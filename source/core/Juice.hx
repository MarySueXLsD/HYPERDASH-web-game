package core;

import flixel.FlxG;
import openfl.Lib;
import states.BaseState;

/**
 * Game feel. Shake is a decaying "trauma" value (shake = trauma²) sampled
 * through sines so it is smooth, never a random buzz, and it only moves the
 * camera. Hit-stop drops the time scale and is restored on a real-time clock
 * so a freeze can never get stuck. Events pick a tier so feedback stays
 * proportional across the whole game.
 */
class Juice
{
	static inline var DECAY:Float = 1.6;
	static inline var MAX_X:Float = 16;
	static inline var MAX_Y:Float = 11;
	static inline var MAX_ROLL:Float = 1.6;

	public static var trauma:Float = 0;

	static var t:Float = 0;
	static var last:Float = 0;
	static var stopUntil:Float = 0;
	static var stopping:Bool = false;
	static var ready:Bool = false;

	public static function init():Void
	{
		if (ready)
			return;
		ready = true;
		last = Lib.getTimer();
		FlxG.signals.preUpdate.add(update);
		FlxG.signals.preStateSwitch.add(reset);
	}

	public static function reset():Void
	{
		trauma = 0;
		stopping = false;
		FlxG.timeScale = 1;
	}

	/** Hits add trauma rather than replacing it. */
	public static function shake(amount:Float):Void
	{
		trauma = Math.min(1, trauma + amount);
	}

	/** Freezes the game for `seconds` of real time. The latest call owns the restore. */
	public static function hitStop(seconds:Float):Void
	{
		FlxG.timeScale = 0.04;
		stopUntil = Math.max(stopUntil, Lib.getTimer() + seconds * 1000);
		stopping = true;
	}

	static function update():Void
	{
		var now:Float = Lib.getTimer();
		var dt = Math.min(0.1, (now - last) / 1000);
		last = now;
		if (stopping && now >= stopUntil)
		{
			stopping = false;
			FlxG.timeScale = 1;
		}
		var cam = FlxG.camera;
		if (cam == null)
			return;
		trauma = Math.max(0, trauma - DECAY * dt);
		t += dt * 32;
		var s = G.shakeOn ? trauma * trauma : 0;
		cam.scroll.set(MAX_X * s * Math.sin(t * 1.7), MAX_Y * s * Math.sin(t * 2.3 + 1.3));
		cam.angle = MAX_ROLL * s * Math.sin(t * 1.1 + 0.4);
	}

	// ------------------------------------------------------------------ tiers

	static function host():BaseState
	{
		return Std.downcast(FlxG.state, BaseState);
	}

	/** Taps, pickups, UI presses. */
	public static function small(x:Float, y:Float, color:Int):Void
	{
		var h = host();
		if (h != null)
			h.sparks.burst(x, y, color, 6, 220, 0.3, 0.45);
		shake(0.12);
	}

	/** A cleared game, a correct step in a sequence. */
	public static function medium(x:Float, y:Float, color:Int):Void
	{
		var h = host();
		if (h != null)
		{
			h.sparks.burst(x, y, color, 18, 380, 0.55, 0.65);
			h.sparks.shock(x, y, color, 1);
			h.kick(0.5);
		}
		shake(0.3);
		hitStop(0.05);
	}

	/** Crashes, lost cargo, a boss clear. */
	public static function large(x:Float, y:Float, color:Int):Void
	{
		var h = host();
		if (h != null)
		{
			h.sparks.burst(x, y, color, 36, 540, 0.8, 0.9);
			h.sparks.burst(x, y, 0xFFFFFFFF, 10, 220, 0.4, 0.5);
			h.sparks.shock(x, y, color, 1.5);
			h.sparks.glow(x, y, color, 5, 0.35);
			h.kick(1.4);
			h.flash(0.35);
		}
		shake(0.7);
		hitStop(0.11);
	}
}
