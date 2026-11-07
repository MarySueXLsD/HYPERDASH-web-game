package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import fx.Fx;

class CutsceneState extends FlxState
{
	var kickers = [
		"ORBITAL DOCK AUTHORITY",
		"THE EXAM",
		"THE LINE"
	];
	var titles = [
		"HIRING",
		"YOUR BRAIN",
		"240 IQ"
	];
	var bodies = [
		"Ships park near lightspeed. We need a Probationary FTL Parking Attendant.",
		"Each drill pays IQ. Clear them faster and the pay climbs. +1, then +1.5, then +2.",
		"Hit 240 and you are hired. Miss three and the bay rejects you."
	];
	var page:Int = 0;
	var kicker:FlxText;
	var title:FlxText;
	var body:FlxText;
	var skipHit:FlxSprite;

	override public function create():Void
	{
		Run.boot();
		Fx.mount(this, 1);

		kicker = Gfx.label(30, 160, 480, "", 22, 0xFF9BB4CC);
		title = Gfx.label(30, 230, 480, "", 64, 0xFFF4F8FC);
		body = Gfx.label(40, 430, 460, "", 28, 0xFFE8F7FF, false);
		add(kicker);
		add(title);
		add(body);

		skipHit = Gfx.panel(70, 760, 400, 100, 0xCC10141C);
		add(skipHit);
		var skip = Gfx.label(70, 760, 400, "SKIP", 32, 0xFFF4F8FC, false);
		Gfx.centerIn(skip, 760, 100);
		add(skip);

		show();
		super.create();
	}

	function show():Void
	{
		kicker.text = kickers[page];
		title.text = titles[page];
		body.text = bodies[page];
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!FlxG.mouse.justPressed)
			return;
		if (FlxG.mouse.overlaps(skipHit))
		{
			FlxG.switchState(HubState.new);
			return;
		}
		page++;
		if (page >= titles.length)
			FlxG.switchState(HubState.new);
		else
			show();
	}
}
