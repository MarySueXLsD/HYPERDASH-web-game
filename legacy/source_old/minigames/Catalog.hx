package minigames;

import flixel.FlxG;

typedef RoundMaker = {
	var screen:String;
	var make:Float->MiniGame;
}

class Catalog
{
	static var ALL:Array<RoundMaker>;
	static var bag:Array<RoundMaker> = [];
	static var lastScreen:String;

	public static function reset():Void
	{
		if (ALL == null)
			ALL = build();
		bag = [];
		lastScreen = null;
	}

	public static function pick(speed:Float):MiniGame
	{
		if (ALL == null)
			ALL = build();
		if (bag.length == 0)
			refill();
		var round = bag.pop();
		if (round.screen == lastScreen && bag.length == 0)
			refill();
		if (round.screen == lastScreen && bag.length > 0)
		{
			var swap = 0;
			while (swap < bag.length && bag[swap].screen == lastScreen)
				swap++;
			if (swap < bag.length)
			{
				var other = bag[swap];
				bag[swap] = round;
				round = other;
			}
		}
		lastScreen = round.screen;
		return round.make(speed);
	}

	static function refill():Void
	{
		bag = ALL.copy();
		FlxG.random.shuffle(bag);
		if (lastScreen != null && bag.length > 1 && bag[bag.length - 1].screen == lastScreen)
		{
			var held = bag.pop();
			bag.unshift(held);
		}
	}

	static function build():Array<RoundMaker>
	{
		var all:Array<RoundMaker> = [];
		function three(screen:String, create:Int->Float->MiniGame):Void
		{
			for (rule in 0...3)
			{
				var locked = rule;
				all.push({
					screen: screen,
					make: function(speed) return create(locked, speed)
				});
			}
		}

		three("fly", function(rule, speed) return new TapFly(speed, rule));
		three("hands", function(rule, speed) return new HandsOff(speed, rule));
		three("jump", function(rule, speed) return new SwipeUp(speed, rule));
		three("arrow", function(rule, speed) return new SwipeArrow(speed, rule));
		three("meter", function(rule, speed) return new HoldMeter(speed, rule));
		three("green", function(rule, speed) return new LetGo(speed, rule));
		three("coin", function(rule, speed) return new CatchFall(speed, rule));
		three("sides", function(rule, speed) return new StepAside(speed, rule));
		three("colors", function(rule, speed) return new TapColor(speed, rule));
		three("count", function(rule, speed) return new ExactTaps(speed, rule));
		three("zone", function(rule, speed) return new StopZone(speed, rule));
		three("faces", function(rule, speed) return new SmileSkull(speed, rule));
		three("bubble", function(rule, speed) return new KeepUp(speed, rule));
		three("pads", function(rule, speed) return new CopyPads(speed, rule));
		three("light", function(rule, speed) return new WaitGreen(speed, rule));
		three("redlie", function(rule, speed) return new TapRedLie(speed, rule));
		three("small", function(rule, speed) return new TapSmall(speed, rule));
		three("downarrow", function(rule, speed) return new SwipeDownLie(speed, rule));
		three("once", function(rule, speed) return new TapOnce(speed, rule));
		three("lefthalf", function(rule, speed) return new TapLeftLie(speed, rule));
		three("empty", function(rule, speed) return new TapEmpty(speed, rule));
		three("shapes", function(rule, speed) return new TapCircle(speed, rule));
		three("stack", function(rule, speed) return new TapBottom(speed, rule));
		three("sign", function(rule, speed) return new TapOnStop(speed, rule));
		three("five", function(rule, speed) return new TapTwoLie(speed, rule));
		three("holdlie", function(rule, speed) return new LetGoLie(speed, rule));
		three("flash", function(rule, speed) return new TapRightIgnore(speed, rule));
		three("dark", function(rule, speed) return new TapDark(speed, rule));
		three("leftarrow", function(rule, speed) return new SwipeLeftLie(speed, rule));
		three("falling", function(rule, speed) return new LetFall(speed, rule));
		return all;
	}
}
