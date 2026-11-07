package games;

import core.Input;
import core.Art;
import core.Juice;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import fx.Sparks;
import states.BaseState;

/**
 * Base for every mini game. A game is built frozen behind the prompt, `start()`
 * arms it, and it ends by calling `win()` or `lose()` or when the fuse burns out.
 * After it ends `tick` keeps running so outro animations can play.
 */
class Micro extends FlxGroup
{
	public var level:Int;
	public var speed:Float;
	public var duration:Float;
	public var timeLeft:Float;
	public var finished:Bool = false;
	public var won:Bool = false;
	public var armed:Bool = false;

	/** When true the player wins if the fuse runs out (survival games). */
	public var survive:Bool = false;

	/** Seconds the result is held on screen before returning to the bridge. */
	public var outro:Float = 0.6;

	public var host:BaseState;
	public var fx:Sparks;

	var beat:Float;
	var downX:Float = 0;
	var downY:Float = 0;
	var swipeUsed:Bool = true;
	var pressFresh:Bool = false;
	var swipeDir:Int = -1;

	public function new(level:Int, speed:Float, beats:Float)
	{
		super();
		this.level = level;
		this.speed = speed;
		beat = G.beat(speed);
		duration = beats * beat;
		timeLeft = duration;
	}

	public function attach(host:BaseState):Void
	{
		this.host = host;
		this.fx = host.sparks;
		setup();
	}

	/** Build the scene. Called once the host is known. */
	function setup():Void {}

	public function start():Void
	{
		armed = true;
		pressFresh = false;
		swipeUsed = true;
	}

	override public function update(elapsed:Float):Void
	{
		if (!armed)
			return;
		readInput();
		super.update(elapsed);
		tick(elapsed);
		if (!finished)
		{
			timeLeft -= elapsed;
			if (timeLeft <= 0)
			{
				timeLeft = 0;
				timeout();
			}
		}
	}

	function tick(elapsed:Float):Void {}

	function timeout():Void
	{
		if (survive)
			win();
		else
			lose();
	}

	function win():Void
	{
		if (finished)
			return;
		finished = true;
		won = true;
	}

	function lose():Void
	{
		if (finished)
			return;
		finished = true;
		won = false;
	}

	// ----------------------------------------------------------------- input

	function readInput():Void
	{
		var m = FlxG.mouse;
		swipeDir = -1;
		if (Input.justPressed)
		{
			downX = m.x;
			downY = m.y;
			swipeUsed = false;
			pressFresh = true;
		}
		if (!m.pressed && !Input.justReleased)
			pressFresh = false;
		if ((m.pressed || Input.justReleased) && !swipeUsed)
		{
			var dx = m.x - downX;
			var dy = m.y - downY;
			if (dx * dx + dy * dy > 55 * 55)
			{
				swipeUsed = true;
				if (Math.abs(dx) > Math.abs(dy))
					swipeDir = dx > 0 ? 1 : 3;
				else
					swipeDir = dy > 0 ? 2 : 0;
			}
		}
		var k = FlxG.keys;
		if (k.justPressed.UP || k.justPressed.W)
			swipeDir = 0;
		if (k.justPressed.RIGHT || k.justPressed.D)
			swipeDir = 1;
		if (k.justPressed.DOWN || k.justPressed.S)
			swipeDir = 2;
		if (k.justPressed.LEFT || k.justPressed.A)
			swipeDir = 3;
	}

	inline function live():Bool
	{
		return armed && !finished;
	}

	function tapped():Bool
	{
		return live() && (Input.justPressed || FlxG.keys.justPressed.SPACE);
	}

	/** Pressing, but only if the press began after the game started. */
	function held():Bool
	{
		return live() && ((FlxG.mouse.pressed && pressFresh) || FlxG.keys.pressed.SPACE);
	}

	function released():Bool
	{
		return live() && ((Input.justReleased && pressFresh) || FlxG.keys.justReleased.SPACE);
	}

	/** 0 up, 1 right, 2 down, 3 left, or -1. Fires once per gesture. */
	function swiped():Int
	{
		return live() ? swipeDir : -1;
	}

	var px(get, never):Float;
	var py(get, never):Float;

	inline function get_px():Float
		return FlxG.mouse.x;

	inline function get_py():Float
		return FlxG.mouse.y;

	function near(s:FlxSprite, r:Float):Bool
	{
		var dx = px - Art.cx(s);
		var dy = py - Art.cy(s);
		return dx * dx + dy * dy < r * r;
	}

	static inline function dist(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var dx = x2 - x1;
		var dy = y2 - y1;
		return Math.sqrt(dx * dx + dy * dy);
	}

	// --------------------------------------------------------------- effects

	/** An explosion. Big ones are crashes (large feedback tier); small ones are targets popping. */
	function boom(x:Float, y:Float, color:Int = 0xFFFF5B1F, big:Bool = true):Void
	{
		Audio.sfx(big ? "boom" : "pop");
		if (big)
			Juice.large(x, y, color);
		else
		{
			Juice.small(x, y, color);
			fx.burst(x, y, color, 12, 320, 0.45, 0.6);
			fx.shock(x, y, color, 0.8);
		}
	}

	/** A local success flourish. The run adds the medium tier on top when the game ends. */
	function cheer(x:Float, y:Float, color:Int = 0xFF58D68D):Void
	{
		fx.burst(x, y, color, 16, 340, 0.5, 0.6);
		fx.shock(x, y, color, 1.1);
	}

	/** Places the hero ship and its flame. Call `flameTo` each frame to keep the flame attached. */
	function heroShip():FlxSprite
	{
		var f = Art.flame();
		add(f);
		var r = G.run;
		var s = r != null ? core.Pilots.ship(core.Pilots.get(r.pilot)) : Art.ship();
		add(s);
		s.ID = members.indexOf(f);
		return s;
	}

	function flameTo(s:FlxSprite, power:Float = 1, size:Float = 1):Void
	{
		var f:FlxSprite = cast members[s.ID];
		var rad = s.angle * Math.PI / 180;
		var ox = -Math.sin(rad) * (s.height / 2 - 18) * size;
		var oy = Math.cos(rad) * (s.height / 2 - 18) * size;
		f.x = Art.cx(s) + ox - f.width / 2;
		f.y = Art.cy(s) + oy - 12;
		f.angle = s.angle;
		var k = (0.8 + Math.random() * 0.35) * power;
		f.scale.set(Math.max(0.4, k * 0.9) * size, k * size);
		f.visible = s.visible && power > 0.05;
	}
}
