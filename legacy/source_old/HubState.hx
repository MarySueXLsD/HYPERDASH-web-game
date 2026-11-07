package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import fx.Fx;

class HubState extends FlxState
{
	var nextHit:FlxSprite;

	override public function create():Void
	{
		Run.boot();
		Fx.mount(this, 1);

		add(Gfx.label(20, 90, 500, "APTITUDE BAY", 22, 0xFF9BB4CC));
		add(Gfx.label(20, 140, 500, Run.round > 0 ? "FASTER" : "READY", 64, 0xFFF4F8FC));
		add(Gfx.label(20, 230, 500, Run.rank(), 26, 0xFFD6C48A));

		add(Gfx.label(20, 300, 500, "IQ", 20, 0xFF9BB4CC, false));
		add(Gfx.label(20, 330, 500, Run.iqText(Run.iq), 72, 0xFFF4F8FC));
		add(Gfx.label(20, 420, 500, "OF 240", 24, 0xFF8AA0B4, false));

		add(Gfx.panel(40, 470, 460, 18, 0xFF12161E));
		var fill = Gfx.panel(40, 470, 460, 18, 0xFFD6C48A);
		var ratio = Run.iq / Run.WIN_IQ;
		if (ratio > 1)
			ratio = 1;
		Gfx.clipWidth(fill, 460, ratio);
		add(fill);

		add(Gfx.label(20, 510, 500, "EACH CLEAR", 22, 0xFF9BB4CC, false));
		add(Gfx.label(20, 540, 500, Run.gainLabel(), 48, 0xFFD6C48A));

		var span = Run.MAX_HEARTS * 42 - 6;
		var start = (Run.W - span) / 2;
		for (i in 0...Run.MAX_HEARTS)
		{
			var heart = Gfx.heart();
			heart.x = start + i * 42;
			heart.y = 630;
			heart.color = i < Run.hearts ? 0xFFFFFFFF : 0xFF2A2438;
			add(heart);
		}

		nextHit = Gfx.panel(70, 720, 400, 140, 0xCC0C1218);
		add(nextHit);
		var next = Gfx.label(70, 720, 400, "BEGIN", 42, 0xFFF4F8FC, false);
		Gfx.centerIn(next, 720, 140);
		add(next);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(nextHit))
			FlxG.switchState(PlayState.new);
	}
}
