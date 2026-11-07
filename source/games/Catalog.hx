package games;

typedef GameInfo =
{
	var id:String;
	var verb:String;
	var hint:String;
	var blurb:String;
	var make:(Int, Float) -> Micro;
}

class Catalog
{
	public static inline var BOSS:String = "hyperlane";

	public static var ALL:Array<GameInfo> = [
		{id: "dodge", verb: "DODGE!", hint: "DRAG", blurb: "Weave through falling rocks", make: (l, s) -> new Dodge(l, s)},
		{id: "blast", verb: "BLAST!", hint: "TAP", blurb: "Shoot down every drone", make: (l, s) -> new Blast(l, s)},
		{id: "dock", verb: "DOCK!", hint: "TAP", blurb: "Launch when lined up", make: (l, s) -> new Dock(l, s)},
		{id: "boost", verb: "BOOST!", hint: "MASH", blurb: "Out-thrust the rival", make: (l, s) -> new Boost(l, s)},
		{id: "stabilize", verb: "STABILIZE!", hint: "HOLD + RELEASE", blurb: "Charge the core into the zone", make: (l, s) -> new Stabilize(l, s)},
		{id: "jump", verb: "JUMP!", hint: "TAP ON THE RING", blurb: "Time the warp ring", make: (l, s) -> new Jump(l, s)},
		{id: "rewire", verb: "REWIRE!", hint: "DRAG", blurb: "Match the coloured cables", make: (l, s) -> new Rewire(l, s)},
		{id: "grab", verb: "GRAB!", hint: "DRAG", blurb: "Collect every energy cell", make: (l, s) -> new Grab(l, s)},
		{id: "evade", verb: "EVADE!", hint: "SWIPE", blurb: "Roll in the arrow's direction", make: (l, s) -> new Evade(l, s)},
		{id: "land", verb: "LAND!", hint: "HOLD", blurb: "Touch down gently", make: (l, s) -> new Land(l, s)},
		{id: "lock", verb: "LOCK ON!", hint: "HOLD ON TARGET", blurb: "Keep the target in your sights", make: (l, s) -> new LockOn(l, s)},
		{id: "sling", verb: "SLINGSHOT!", hint: "TAP", blurb: "Release through the gate", make: (l, s) -> new Slingshot(l, s)},
		{id: "spy", verb: "SPOT THE SPY!", hint: "TAP", blurb: "Find the impostor ship", make: (l, s) -> new Spy(l, s)},
		{id: "flip", verb: "FLIP!", hint: "TAP", blurb: "Swap gravity, dodge spikes", make: (l, s) -> new Flip(l, s)},
		{id: "sort", verb: "SORT!", hint: "SWIPE LEFT / RIGHT", blurb: "Send each parcel to its bay", make: (l, s) -> new Sort(l, s)},
		{id: "stamp", verb: "STAMP!", hint: "TAP CLEAN PARCELS", blurb: "Stamp the good, skip the bombs", make: (l, s) -> new Stamp(l, s)},
		{id: "keypad", verb: "KEYPAD!", hint: "REPEAT THE CODE", blurb: "Watch the code, tap it back", make: (l, s) -> new Keypad(l, s)},
		{id: "balance", verb: "BALANCE!", hint: "DRAG LEFT / RIGHT", blurb: "Keep the parcel on the tray", make: (l, s) -> new Balance(l, s)},
		{id: "crank", verb: "CRANK!", hint: "SPIN IN CIRCLES", blurb: "Wind up the backup generator", make: (l, s) -> new Crank(l, s)},
		{id: "slice", verb: "SLICE!", hint: "SWIPE THE JUNK", blurb: "Cut the junk, spare the parcels", make: (l, s) -> new Slice(l, s)},
		{id: "scan", verb: "SCAN!", hint: "DRAG TO SEARCH", blurb: "Find the parcel in the dark hold", make: (l, s) -> new Scan(l, s)},
		{id: "shuffle", verb: "SHUFFLE!", hint: "FOLLOW THE PARCEL", blurb: "Track the pod with the parcel", make: (l, s) -> new Shuffle(l, s)},
		{id: "route", verb: "ROUTE!", hint: "TAP THE SWITCHES", blurb: "Steer the parcel to its bay", make: (l, s) -> new Route(l, s)},
		{id: "stack", verb: "STACK!", hint: "TAP TO DROP", blurb: "Stack the crates neatly", make: (l, s) -> new Stack(l, s)},
		{id: BOSS, verb: "HYPERLANE!", hint: "TAP LEFT / RIGHT", blurb: "Boss: survive the hyperlane", make: (l, s) -> new Hyperlane(l, s)}
	];

	public static function get(id:String):GameInfo
	{
		for (g in ALL)
			if (g.id == id)
				return g;
		return ALL[0];
	}

	public static function ids(withBoss:Bool):Array<String>
	{
		return [for (g in ALL) if (withBoss || g.id != BOSS) g.id];
	}
}
