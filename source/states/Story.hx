package states;

import core.G;
import core.Pilots;

enum Cmd
{
	Scene(piece:String, sector:Int);
	Card(kicker:String, title:String, ?sub:String);
	Say(who:String, text:String);
	ShipIn;
	ShipOut;
	ShipShake;
	Prop(name:String);
	Warp(stretch:Float);
	Wait(t:Float);
	Flash;
	Sfx(name:String);
	Music(name:String);
}

/**
 * All dialogue. The story is a relay of five pilots carrying one parcel:
 * Nova, then Vex, Captain Rust, Kade and finally PIP. Losing hands the parcel
 * to the next pilot, whose story picks up from the wreck.
 */
class Story
{
	public static function script(id:String):Array<Cmd>
	{
		var p = G.run != null ? G.run.pilot : 0;
		var lines = switch (p)
		{
			case 0: nova(id);
			case 1: vex(id);
			case 2: rust(id);
			case 3: kade(id);
			default: pip(id);
		}
		return wrap(p, id, lines);
	}

	/** Shared staging around each pilot's lines: music, scenery, ship moves and cards. */
	static function wrap(p:Int, id:String, lines:Array<Cmd>):Array<Cmd>
	{
		var pilot = Pilots.get(p);
		var late = G.run != null && G.run.late;
		switch (id)
		{
			case "intro":
				var out:Array<Cmd> = [
					Music("cut"),
					Scene(p == 0 ? "station" : "wreck", 0),
					Warp(0.02),
					Card('Pilot ${p + 1} of ${Pilots.ALL.length}', pilot.name.toUpperCase(), pilot.role + ".\n" + pilot.perk),
					ShipIn
				];
				return out.concat(lines).concat([Sfx("speedup"), Warp(1), ShipOut, Wait(0.6)]);
			case "sector1", "sector2", "sector3", "sector4":
				var n = Std.parseInt(id.substr(6));
				var piece = G.sector(n).piece;
				var out:Array<Cmd> = [Music("cut"), Scene(piece, n), Warp(0.12), ShipIn];
				return out.concat(lines).concat([Sfx("speedup"), Warp(1), ShipOut, Wait(0.5)]);
			case "ending":
				var out:Array<Cmd> = [Music("win"), Scene("planet", 0), Warp(0.02), ShipIn];
				out = out.concat(lines);
				if (late)
					out = out.concat([
						Say("ZIB", "The tracker said you'd be here ages ago, though. So it's free, right?"),
						Say("DISPATCH", "It's free. Beat the guarantee next time for the full ending."),
						Card("Proof of delivery", "LATE\nBUT HERE", "Delivered by " + pilot.name + ", eventually.")
					]);
				else
					out.push(Card("Proof of delivery", "SIGNED\nFOR", "Delivered by " + pilot.name + ". Thanks for flying HyperDash."));
				return out;
			case "gameover":
				var out:Array<Cmd> = [Music("over"), Scene("none", 0), Warp(0.0), ShipIn, ShipShake, Sfx("boom")];
				out = out.concat(lines);
				if (p < Pilots.ALL.length - 1)
				{
					var next = Pilots.get(p + 1);
					out.push(Card("The parcel's beacon is still blinking", "NEXT:\n" + next.name.toUpperCase(), next.role));
				}
				else
					out.push(Card("The parcel drifts on", "RELAY\nLOST", "All five couriers are down. The relay starts over with Nova."));
				return out;
			default:
				return lines;
		}
	}

	// ----------------------------------------------------------------- Nova

	static function nova(id:String):Array<Cmd>
	{
		return switch (id)
		{
			case "intro": [
					Say("DISPATCH", "Courier Seven, wake up. Priority order just landed."),
					Say("NOVA", "Dispatch, it's three in the morning. Galactic standard."),
					Say("DISPATCH", "Customer's on the far side of the Orion Arm. Two minutes of flying on the guarantee."),
					Say("PIP", "Two minutes. Forty thousand light-years. In this ship."),
					Say("DISPATCH", "Or it's free. And 'free' comes out of your paycheck, Nova."),
					Say("PIP", "Things WILL break. Fix them fast: the clock only runs while you're fixing."),
					Say("NOVA", "Then we'd better be fast.")
				];
			case "sector1": [
					Say("PIP", "Docks cleared. The short route runs straight through the Shatterbelt."),
					Say("NOVA", "Define 'through'."),
					Say("PIP", "Like a needle through a haystack. Where the hay is rocks."),
					Say("NOVA", "Pushing the drive past spec. Hold on.")
				];
			case "sector2": [
					Sfx("alarm"),
					Say("PIP", "Incoming hail. Rust Corsairs. They want the parcel."),
					Say("RUST", "Heave to, courier! Nobody outruns the Rust Corsairs!"),
					Say("VEX", "Captain, she isn't slowing down. She's speeding UP."),
					Say("NOVA", "Has anyone tried at warp three?"),
					Say("RUST", "...Warp WHAT?")
				];
			case "sector3": [
					Say("DISPATCH", "Heads up, Seven. Galactic Customs has thrown a cordon across the route."),
					Say("NOVA", "Do we have the paperwork?"),
					Say("PIP", "We have a parcel, a dent and forty-one unpaid speeding tickets."),
					Say("NOVA", "Then we don't stop.")
				];
			case "sector4": [
					Say("PIP", "Last shortcut: we skim the event horizon. Time slows down near it."),
					Say("NOVA", "So if we're fast enough, the clock barely moves."),
					Say("PIP", "That is not how physics works. ...Actually, it sort of is."),
					Say("NOVA", "Redline it, PIP.")
				];
			case "ending": [
					Say("ZIB", "Ooh! A HyperDash!"),
					Say("NOVA", "One parcel, delivered at the speed of light. Sign here."),
					Prop("parcel"),
					Sfx("pop"),
					Say("ZIB", "My limited-edition rubber duck! Bath time is SAVED!"),
					Prop("duck"),
					Sfx("coin"),
					Say("PIP", "We broke the light barrier. For a duck."),
					Say("DISPATCH", "Outstanding, Seven. New order: Andromeda. Four minutes.")
				];
			case "gameover": [
					Say("PIP", "Hull integrity: zero. We're dead in the vacuum."),
					Say("NOVA", "The parcel's intact. Turn its beacon on, PIP. Somebody has to finish this."),
					Say("PIP", "Beacon on. Who'd be desperate enough to pick it up?")
				];
			default: [];
		}
	}

	// ------------------------------------------------------------------ Vex

	static function vex(id:String):Array<Cmd>
	{
		return switch (id)
		{
			case "intro": [
					Say("VEX", "A HyperDash wreck, and a parcel still blinking. Captain, look at this."),
					Say("RUST", "Smash it open! Treasure!"),
					Say("DISPATCH", "This is HyperDash dispatch. Whoever delivers that parcel collects the full tip."),
					Say("VEX", "The full tip? ...Captain, I'm borrowing the fast ship."),
					Say("RUST", "Bring back the money, Vex. And the ship. Mostly the money.")
				];
			case "sector1": [
					Say("VEX", "Courier lanes are tighter than I thought. Everyone drives like they're late."),
					Say("DISPATCH", "They are late. That's the job."),
					Say("VEX", "I'm starting to respect these people.")
				];
			case "sector2": [
					Sfx("alarm"),
					Say("RUST", "Vex! You flew straight past the hideout!"),
					Say("VEX", "Can't stop, Captain. Stopping costs tips."),
					Say("RUST", "...I taught you well.")
				];
			case "sector3": [
					Say("DISPATCH", "Customs cordon ahead. They'll want to see your papers."),
					Say("VEX", "I'm a pirate. My papers are a cutlass and a smile."),
					Say("DISPATCH", "Please show them neither.")
				];
			case "sector4": [
					Say("DISPATCH", "Event horizon ahead. Our couriers skim it all the time."),
					Say("VEX", "How many come back?"),
					Say("DISPATCH", "The fast ones.")
				];
			case "ending": [
					Say("ZIB", "A pirate?! Are you robbing me?"),
					Say("VEX", "Delivering, kid. It's a new career. Sign here."),
					Prop("parcel"),
					Sfx("pop"),
					Say("ZIB", "My rubber duck! You're the nicest pirate ever!"),
					Prop("duck"),
					Sfx("coin"),
					Say("VEX", "Tell nobody.")
				];
			case "gameover": [
					Say("VEX", "Engines gone. Captain, I'm adrift. The parcel's still blinking."),
					Say("RUST", "Hold on, Vex. I'm coming for you. And the parcel. Mostly the parcel."),
					Say("RUST", "Ready my ship! Rust flies himself!")
				];
			default: [];
		}
	}

	// ----------------------------------------------------------------- Rust

	static function rust(id:String):Array<Cmd>
	{
		return switch (id)
		{
			case "intro": [
					Say("RUST", "Two hundred years of piracy, and now I'm a delivery boy."),
					Say("VEX", "You've got more cargo space than anyone, Captain. Just go fast."),
					Say("RUST", "These bones don't go fast. These bones go DRAMATIC."),
					Say("DISPATCH", "A hundred seconds on your guarantee. Your ship is harder to insure.")
				];
			case "sector1": [
					Say("RUST", "Rocks! I used to hide in these rocks!"),
					Say("VEX", "Captain, focus. You're going the wrong way."),
					Say("RUST", "No such thing, when you go fast enough.")
				];
			case "sector2": [
					Say("RUST", "Home waters. My own crew is chasing me."),
					Say("VEX", "You told them nobody outruns the Rust Corsairs."),
					Say("RUST", "Then I'd better be the first.")
				];
			case "sector3": [
					Say("RUST", "Customs! They've been after me for two hundred years!"),
					Say("VEX", "Captain, the warrants expired. You died."),
					Say("RUST", "Then they owe ME a refund.")
				];
			case "sector4": [
					Say("DISPATCH", "Captain, the event horizon will stretch you thin."),
					Say("RUST", "Madam, I am already very thin.")
				];
			case "ending": [
					Say("ZIB", "AAAH! A SKELETON!"),
					Say("RUST", "A courier skeleton. Sign here, small one."),
					Prop("parcel"),
					Sfx("pop"),
					Say("ZIB", "My duck! ...You can stay for bath time if you want."),
					Prop("duck"),
					Sfx("coin"),
					Say("RUST", "I don't float. But thank you.")
				];
			case "gameover": [
					Say("RUST", "My bones! My beautiful bones are everywhere!"),
					Say("KADE", "SwiftHaul here. I'll take that parcel off your hands, Captain."),
					Say("RUST", "A rival courier? Fine. Just get it there before HyperDash does.")
				];
			default: [];
		}
	}

	// ----------------------------------------------------------------- Kade

	static function kade(id:String):Array<Cmd>
	{
		return switch (id)
		{
			case "intro": [
					Say("KADE", "A HyperDash parcel, three wrecks, and nobody's finished the job."),
					Say("DISPATCH", "Kade. SwiftHaul. Of course it's you."),
					Say("KADE", "Give me the coordinates and I'll show you what a real courier does."),
					Say("DISPATCH", "SwiftHaul has never delivered anything on time."),
					Say("KADE", "First time for everything.")
				];
			case "sector1": [
					Say("KADE", "My ship runs hot from the start. No warm-up, no excuses."),
					Say("DISPATCH", "It also catches fire, according to our files."),
					Say("KADE", "Only when I'm winning.")
				];
			case "sector2": [
					Sfx("alarm"),
					Say("VEX", "That's the parcel the Captain lost! After him!"),
					Say("KADE", "Pirates, wrecks, a skeleton. This parcel has a following."),
					Say("DISPATCH", "Just don't drop it.")
				];
			case "sector3": [
					Say("DISPATCH", "SwiftHaul's customs account is overdue, Kade."),
					Say("KADE", "By how much?"),
					Say("DISPATCH", "Since the day you were founded."),
					Say("KADE", "Then I'm not stopping to chat.")
				];
			case "sector4": [
					Say("KADE", "Event horizon. If I clear this, SwiftHaul finally beats HyperDash."),
					Say("DISPATCH", "If you clear this, I'll write you a good review myself.")
				];
			case "ending": [
					Say("ZIB", "SwiftHaul? I ordered HyperDash."),
					Say("KADE", "Long story. Four pilots long. Sign here."),
					Prop("parcel"),
					Sfx("pop"),
					Say("ZIB", "My duck! Five stars, SwiftHaul!"),
					Prop("duck"),
					Sfx("coin"),
					Say("DISPATCH", "Fine. One star off for the attitude.")
				];
			case "gameover": [
					Say("KADE", "Reactor's out. I was SO close."),
					Say("PIP", "Courier Kade, this is PIP, Nova's ship AI. I've loaded myself into a cargo drone."),
					Say("PIP", "Hand me the parcel. I'm finishing what Nova started.")
				];
			default: [];
		}
	}

	// ------------------------------------------------------------------ PIP

	static function pip(id:String):Array<Cmd>
	{
		return switch (id)
		{
			case "intro": [
					Say("PIP", "New body. Cargo drone. Three thrusters, no cup holder."),
					Say("NOVA", "PIP? You're flying it yourself?"),
					Say("PIP", "You're on the radio, Nova. Coach me. Everyone else is a wreck."),
					Say("DISPATCH", "PIP, you get one hundred and sixty seconds. It's the last chance for this parcel."),
					Say("NOVA", "Fast hands, PIP. You've watched me do it a thousand times.")
				];
			case "sector1": [
					Say("NOVA", "Remember: the clock only runs while you're fixing things."),
					Say("PIP", "I am the thing that needs fixing. This drone has opinions.")
				];
			case "sector2": [
					Sfx("alarm"),
					Say("RUST", "Is that... the ship's AI? Flying itself?"),
					Say("VEX", "Captain, let it go. It's earned it.")
				];
			case "sector3": [
					Say("NOVA", "Customs will ask for a pilot's licence."),
					Say("PIP", "I am a ship's AI in a cargo drone. I am both the pilot and the undeclared goods."),
					Say("NOVA", "Just keep moving.")
				];
			case "sector4": [
					Say("NOVA", "The event horizon. You know what to do."),
					Say("PIP", "Redline it. I learned that from you."),
					Say("NOVA", "...Yeah. Go.")
				];
			case "ending": [
					Say("ZIB", "A tiny drone! Are you the delivery?"),
					Say("PIP", "On behalf of four pilots and one stubborn AI: your parcel."),
					Prop("parcel"),
					Sfx("pop"),
					Say("ZIB", "My duck!!"),
					Prop("duck"),
					Sfx("coin"),
					Say("NOVA", "You did it, PIP."),
					Say("PIP", "We did it. Now somebody please come and get me. I have no landing gear.")
				];
			case "gameover": [
					Say("PIP", "Drone down. Parcel... drifting."),
					Say("NOVA", "You flew it further than any of us, PIP."),
					Say("DISPATCH", "Relay closed. We'll start again with Nova. HyperDash never gives up a parcel.")
				];
			default: [];
		}
	}
}
