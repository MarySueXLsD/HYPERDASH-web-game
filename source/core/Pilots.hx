package core;

import flixel.FlxG;
import flixel.FlxSprite;

typedef Pilot =
{
	/** Speaker id, also the portrait file name. */
	var id:String;
	var name:String;
	var role:String;
	/** One line describing the perk, shown on the intro card and the title screen. */
	var perk:String;
	var lives:Int;
	var guarantee:Float;
	var speedBonus:Float;
	var tipMult:Float;
	var tint:Int;
}

/**
 * The story is a relay. One parcel, five couriers: when a pilot goes down,
 * the next one picks the parcel out of the wreck and carries on. Each pilot
 * plays differently, so every hand-off changes the run.
 */
class Pilots
{
	public static var ALL:Array<Pilot> = [
		{
			id: "NOVA",
			name: "Nova",
			role: "HyperDash courier, night shift",
			perk: "4 parcels of cargo, 120 second guarantee. The all-rounder.",
			lives: 4,
			guarantee: 120,
			speedBonus: 0,
			tipMult: 1,
			tint: 0xFF5A7AE0
		},
		{
			id: "VEX",
			name: "Vex",
			role: "Corsair first mate, salvager",
			perk: "Only 3 parcels, but tips pay 50% more. Greedy.",
			lives: 3,
			guarantee: 120,
			speedBonus: 0,
			tipMult: 1.5,
			tint: 0xFF3FD6C2
		},
		{
			id: "RUST",
			name: "Captain Rust",
			role: "Corsair captain, mostly bones",
			perk: "5 parcels of cargo, but only a 100 second guarantee.",
			lives: 5,
			guarantee: 100,
			speedBonus: 0,
			tipMult: 1,
			tint: 0xFF58D68D
		},
		{
			id: "KADE",
			name: "Kade",
			role: "SwiftHaul courier, HyperDash's rival",
			perk: "Starts at higher warp, with a 140 second guarantee.",
			lives: 4,
			guarantee: 140,
			speedBonus: 0.15,
			tipMult: 1.2,
			tint: 0xFF2FA866
		},
		{
			id: "PIP",
			name: "PIP",
			role: "Ship AI in a borrowed courier drone",
			perk: "3 parcels and a 160 second guarantee. The last chance.",
			lives: 3,
			guarantee: 160,
			speedBonus: -0.05,
			tipMult: 1,
			tint: 0xFF3CF0FF
		}
	];

	/**
	 * Colour rule: the player's side is blue or green, enemies are red. Vex, Rust and
	 * Kade change sides across the relay, so who counts as hostile depends on whose
	 * story is playing.
	 */
	static var HOSTILE:Array<Array<String>> = [["RUST", "VEX"], [], [], ["VEX"], ["RUST"]];

	public static function hostile(who:String):Bool
	{
		var r = G.run;
		var p = r != null && r.mode == STORY ? r.pilot : 0;
		return HOSTILE[p].indexOf(who) >= 0;
	}

	/** Which pilot the story campaign is on (saved between sessions). */
	public static function current():Int
	{
		var v:Dynamic = FlxG.save.data.pilot;
		return v == null ? 0 : Std.int(Math.min(ALL.length - 1, Std.int(v)));
	}

	public static function setCurrent(i:Int):Void
	{
		FlxG.save.data.pilot = i;
		FlxG.save.flush();
	}

	public static inline function get(i:Int):Pilot
	{
		return ALL[Std.int(Math.max(0, Math.min(ALL.length - 1, i)))];
	}

	public static function ship(p:Pilot):FlxSprite
	{
		return Art.ship(p.tint, "ship_" + p.id);
	}
}
