package;

import flixel.FlxG;
import flixel.system.scaleModes.RatioScaleMode;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

class Run
{
	public static inline var W:Int = 540;
	public static inline var H:Int = 960;
	public static inline var MAX_HEARTS:Int = 3;
	public static inline var SET:Int = 4;
	public static inline var WIN_IQ:Float = 240;

	public static var hearts:Int;
	public static var iq:Float;
	public static var round:Int;
	public static var speed:Float;
	public static var tier:Int;

	public static function boot():Void
	{
		FlxG.scaleMode = new RatioScaleMode();
		FlxG.autoPause = false;
		FlxG.mouse.useSystemCursor = true;
		Mouse.cursor = MouseCursor.ARROW;
		FlxG.save.bind("badideas");
	}

	public static function reset():Void
	{
		hearts = MAX_HEARTS;
		iq = 0;
		round = 0;
		tier = 0;
		speed = 1;
		minigames.Catalog.reset();
	}

	public static function iqGain():Float
	{
		return 1 + tier * 0.5;
	}

	public static function iqText(value:Float):String
	{
		var tenths = Math.round(value * 10);
		var whole = Std.int(tenths / 10);
		var frac = tenths % 10;
		if (frac == 0)
			return Std.string(whole);
		return whole + "." + frac;
	}

	public static function gainLabel(value:Float = -1):String
	{
		if (value < 0)
			value = iqGain();
		return "+" + iqText(value) + " IQ";
	}

	public static function rank():String
	{
		if (iq >= WIN_IQ)
			return "FTL PARKING ATTENDANT";
		if (iq >= 180)
			return "RELATIVISTIC VALET";
		if (iq >= 120)
			return "NEAR-MISS SPECIALIST";
		if (iq >= 40)
			return "CONE PLACEMENT INTERN";
		return "APPLICANT";
	}

	public static function timeLimit():Float
	{
		return Math.max(1.05, 3.4 / speed);
	}

	public static function dontTapLimit():Float
	{
		return Math.max(0.7, timeLimit() * 0.5);
	}

	public static function pauseTime():Float
	{
		return Math.max(0.32, 0.55 / speed);
	}

	public static function advance():Void
	{
		round++;
	}

	public static function bump():Void
	{
		tier++;
		speed = 1 + tier * 0.1;
	}

	public static function bestIq():Float
	{
		var value:Dynamic = FlxG.save.data.bestIq;
		if (value == null)
			return 0;
		return Std.parseFloat(Std.string(value));
	}

	public static function commitBest():Void
	{
		if (iq > bestIq())
		{
			FlxG.save.data.bestIq = iq;
			FlxG.save.flush();
		}
	}
}
