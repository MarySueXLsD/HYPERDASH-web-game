package core;

import flixel.FlxG;
import core.G.Sector;
import games.Catalog;

enum abstract Mode(Int)
{
	var STORY;
	var ENDLESS;
	var TRAINING;
}

/** State of one play session: lives, score, speed and which game comes next. */
class Run
{
	/** Cargo for non-story modes. Story pilots bring their own. */
	public static inline var LIVES:Int = 4;
	public static inline var PER_SECTOR:Int = 5;

	public var mode:Mode;
	public var sector:Int = 0;
	public var round:Int = 0;
	public var lives:Int = LIVES;
	public var maxLives:Int = LIVES;

	/** Index into Pilots.ALL. Story runs use the campaign's current pilot; other modes fly Nova. */
	public var pilot:Int = 0;
	public var score:Int = 0;
	public var cleared:Int = 0;
	public var played:Int = 0;
	public var streak:Int = 0;
	public var bestStreak:Int = 0;
	public var time:Float = 0;
	public var topSpeed:Float = 1;
	public var trainingId:String;
	public var lastId:String;

	/** Story mode: seconds of flying left on the delivery guarantee. Only ticks while a job is live. */
	public var guarantee:Float = G.GUARANTEE;

	/** True once the guarantee has run out ("or it's free"). */
	public var late:Bool = false;

	/** Fraction of the fuse left when the last job was cleared; drives the fast-clear tip. */
	public var lastFast:Float = 0;

	/** Win/loss of each round in the current sector, for the progress dots. */
	public var results:Array<Bool> = [];

	var bag:Array<String> = [];

	public function new(mode:Mode, ?trainingId:String)
	{
		this.mode = mode;
		this.trainingId = trainingId;
		if (mode == STORY)
		{
			pilot = Pilots.current();
			var p = Pilots.get(pilot);
			lives = maxLives = p.lives;
			guarantee = p.guarantee;
		}
	}

	public var sectorCount(get, never):Int;

	function get_sectorCount():Int
	{
		return G.SECTORS.length;
	}

	/** Warp gained per job. Story mode climbs in one smooth line with no jumps between sectors. */
	static inline var RAMP:Float = 0.028;

	/** Job number at which games step up to level 1 and level 2. */
	static inline var LEVEL_1:Int = 9;

	static inline var LEVEL_2:Int = 21;

	/** Jobs reached so far in the story, counting across sectors. */
	inline function storyStep():Int
	{
		return sector * (PER_SECTOR + 1) + round;
	}

	static inline function levelAt(job:Int):Int
	{
		return job < LEVEL_1 ? 0 : (job < LEVEL_2 ? 1 : 2);
	}

	public function speed():Float
	{
		var s = switch (mode)
		{
			case STORY: 1.0 + storyStep() * RAMP + Pilots.get(pilot).speedBonus;
			case ENDLESS: 1.0 + Math.min(1.5, played * RAMP);
			case TRAINING: 1.0 + Math.min(1.2, streak * 0.08);
		}
		return s;
	}

	public function level():Int
	{
		return switch (mode)
		{
			case STORY: levelAt(storyStep());
			case ENDLESS: levelAt(played);
			case TRAINING: streak < 3 ? 0 : (streak < 7 ? 1 : 2);
		}
	}

	public function isBoss():Bool
	{
		if (mode == TRAINING)
			return trainingId == Catalog.BOSS;
		return round == PER_SECTOR;
	}

	public function nextId():String
	{
		if (mode == TRAINING)
			return trainingId;
		if (isBoss())
			return Catalog.BOSS;
		if (bag.length == 0)
		{
			bag = Catalog.ids(false);
			FlxG.random.shuffle(bag);
			if (bag[bag.length - 1] == lastId)
				bag.unshift(bag.pop());
		}
		return bag.pop();
	}

	public var hasClock(get, never):Bool;

	function get_hasClock():Bool
	{
		return mode == STORY;
	}

	/** Spends guarantee time. Returns true the moment the guarantee runs out. */
	public function spend(seconds:Float):Bool
	{
		if (!hasClock || late)
			return false;
		guarantee -= seconds;
		if (guarantee <= 0)
		{
			guarantee = 0;
			late = true;
			return true;
		}
		return false;
	}

	/**
	 * Records the result of a finished game. `fuseLeft` is the share of the
	 * fuse still unburnt, so faster clears tip more. Returns tips earned.
	 */
	public function record(won:Bool, fuseLeft:Float = 0):Int
	{
		played++;
		results.push(won);
		var gained = 0;
		if (won)
		{
			cleared++;
			streak++;
			if (streak > bestStreak)
				bestStreak = streak;
			lastFast = fuseLeft;
			var fast = 1 + fuseLeft * 0.8;
			var perk = mode == STORY ? Pilots.get(pilot).tipMult : 1;
			gained = Std.int((isBoss() ? 500 : 100) * speed() * fast * perk * (1 + Math.min(streak, 10) * 0.05));
			score += gained;
		}
		else
		{
			lastFast = 0;
			streak = 0;
			lives--;
		}
		if (speed() > topSpeed)
			topSpeed = speed();
		return gained;
	}

	/** Moves to the next round. Returns true when a sector was just completed. */
	public function advance():Bool
	{
		if (mode == TRAINING)
			return false;
		var wasBoss = isBoss();
		round++;
		if (wasBoss)
		{
			round = 0;
			results = [];
			sector++;
			if (mode == ENDLESS && sector >= sectorCount)
				sector = sectorCount - 1;
			return true;
		}
		return false;
	}

	public function storyDone():Bool
	{
		return mode == STORY && sector >= sectorCount;
	}

	public function scoreKey():String
	{
		return switch (mode)
		{
			case STORY: "story";
			case ENDLESS: "endless";
			case TRAINING: "train_" + trainingId;
		}
	}

	/** Endless visuals cycle through sector looks even after the last one. */
	public function look():Sector
	{
		if (mode == ENDLESS)
			return G.sector(Std.int(played / (PER_SECTOR + 1)));
		return G.sector(Std.int(Math.min(sector, sectorCount - 1)));
	}

	public function rank():String
	{
		if (mode != STORY)
			return "";
		var lost = maxLives - lives;
		if (lives <= 0)
			return "F";
		if (late)
			return lost <= 1 ? "B" : "C";
		if (lost == 0)
			return "S";
		if (lost == 1)
			return "A";
		if (lost == 2)
			return "B";
		return "C";
	}
}
