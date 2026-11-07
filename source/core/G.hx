package core;

import flixel.FlxG;
import flixel.system.scaleModes.RatioScaleMode;

typedef Sector =
{
	var name:String;
	var sub:String;
	var tintA:Int;
	var tintB:Int;
	var piece:String;
}

/** Global constants, palette, persistent settings and the save file. */
class G
{
	public static inline var W:Int = 540;
	public static inline var H:Int = 960;
	public static inline var BPM:Float = 128;

	// Palette roles: see ART_DIRECTION.md. In-world light sources use the bright tones;
	// UI is built from paper, kraft and ink.
	public static inline var CYAN:Int = 0xFF3FD6C2; // teal: engines, interactables
	public static inline var MAGENTA:Int = 0xFFE0457B; // corsair rose
	public static inline var ORANGE:Int = 0xFFFF5B1F; // HyperDash safety orange
	public static inline var YELLOW:Int = 0xFFFFC21A; // hazard
	public static inline var GREEN:Int = 0xFF58D68D;
	public static inline var RED:Int = 0xFFE5343F;
	public static inline var WHITE:Int = 0xFFF2F2F5;
	public static inline var DIM:Int = 0xFF9A93B8;
	public static inline var INK:Int = 0xFF211C2B;
	public static inline var PANEL:Int = 0xFF120E22;
	public static inline var VIOLET:Int = 0xFF8C6CFF;
	public static inline var KRAFT:Int = 0xFFD9B98A;
	public static inline var PAPER:Int = 0xFFEEEAE0;
	public static inline var STAMP_GREEN:Int = 0xFF2FA866;
	public static inline var STAMP_RED:Int = 0xFFE5343F;

	/** Seconds of flying time on the story-mode delivery guarantee. */
	public static inline var GUARANTEE:Float = 120;

	public static var SECTORS:Array<Sector> = [
		{name: "Kepler Docks", sub: "Leave the depot without hitting anything expensive", tintA: 0x2A3C9A, tintB: 0x3FD6C2, piece: "station"},
		{name: "The Shatterbelt", sub: "The short route. Through the rocks", tintA: 0xC0602A, tintB: 0x5A3CB0, piece: "rocks"},
		{name: "Corsair Nebula", sub: "Pirates want the parcel", tintA: 0xB0284A, tintB: 0x6A2CB0, piece: "pirates"},
		{name: "Customs Cordon", sub: "Nobody has ever finished the form. Keep moving", tintA: 0x2A8A6A, tintB: 0x2A3C9A, piece: "customs"},
		{name: "Event Horizon", sub: "Skim the black hole, save the clock", tintA: 0xC08A2A, tintB: 0xB0283C, piece: "hole"}
	];

	public static var run:Run;

	public static var musicOn:Bool = true;
	public static var sfxOn:Bool = true;
	public static var screenFx:Bool = true;
	public static var shakeOn:Bool = true;

	static var booted:Bool = false;

	public static function boot():Void
	{
		if (booted)
			return;
		booted = true;
		FlxG.scaleMode = new RatioScaleMode();
		FlxG.autoPause = true;
		FlxG.signals.focusLost.add(function() Audio.suspend(true));
		FlxG.signals.focusGained.add(function() Audio.suspend(false));
		FlxG.mouse.useSystemCursor = true;
		Input.init();
		Juice.init();
		FlxG.save.bind("hyperdash");
		var d = FlxG.save.data;
		if (d.musicOn != null)
			musicOn = d.musicOn;
		if (d.sfxOn != null)
			sfxOn = d.sfxOn;
		if (d.screenFx != null)
			screenFx = d.screenFx;
		if (d.shakeOn != null)
			shakeOn = d.shakeOn;
	}

	/** Seconds per beat at the given speed multiplier. */
	public static inline function beat(speed:Float):Float
	{
		return 60 / (BPM * speed);
	}

	public static function saveSettings():Void
	{
		FlxG.save.data.musicOn = musicOn;
		FlxG.save.data.sfxOn = sfxOn;
		FlxG.save.data.screenFx = screenFx;
		FlxG.save.data.shakeOn = shakeOn;
		FlxG.save.flush();
	}

	public static function best(key:String):Int
	{
		var v:Dynamic = Reflect.field(FlxG.save.data, "best_" + key);
		return v == null ? 0 : Std.int(v);
	}

	/** Stores a score if it beats the previous best. Returns true on a new record. */
	public static function submit(key:String, score:Int):Bool
	{
		if (score <= best(key))
			return false;
		Reflect.setField(FlxG.save.data, "best_" + key, score);
		FlxG.save.flush();
		return true;
	}

	public static function flag(key:String):Bool
	{
		return Reflect.field(FlxG.save.data, "flag_" + key) == true;
	}

	public static function setFlag(key:String):Void
	{
		Reflect.setField(FlxG.save.data, "flag_" + key, true);
		FlxG.save.flush();
	}

	public static function wipeSave():Void
	{
		FlxG.save.erase();
		FlxG.save.bind("hyperdash");
		saveSettings();
	}

	public static function sector(i:Int):Sector
	{
		return SECTORS[i % SECTORS.length];
	}

	public static function pad(n:Int, len:Int):String
	{
		var s = Std.string(n);
		while (s.length < len)
			s = "0" + s;
		return s;
	}

	/** Formats a number with exactly `digits` decimals. */
	public static function fixed(v:Float, digits:Int = 2):String
	{
		var m = Math.pow(10, digits);
		var n = Math.round(v * m);
		var whole = Std.int(n / m);
		return whole + "." + pad(Std.int(n - whole * m), digits);
	}

	/** Largest vector-font size that keeps `text` within `width` pixels. */
	public static function fit(text:String, max:Float, width:Float = 480):Float
	{
		return Math.min(max, width * 6 / ((text.length - 1) * 5.4 + 4));
	}

	/** 12345 -> "12,345" */
	public static function thousands(n:Int):String
	{
		var s = Std.string(n);
		var out = "";
		while (s.length > 3)
		{
			out = "," + s.substr(s.length - 3) + out;
			s = s.substr(0, s.length - 3);
		}
		return s + out;
	}

	public static function clock(seconds:Float):String
	{
		var total = Std.int(seconds * 100);
		var m = Std.int(total / 6000);
		var s = Std.int(total / 100) % 60;
		var cs = total % 100;
		return m + ":" + pad(s, 2) + "." + pad(cs, 2);
	}
}
