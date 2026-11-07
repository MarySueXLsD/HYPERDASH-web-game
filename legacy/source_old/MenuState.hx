package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import fx.Fx;

class MenuState extends FlxState
{
	var playHit:FlxSprite;

	override public function create():Void
	{
		Run.boot();
		Fx.mount(this, 0);

		add(Gfx.label(20, 180, 500, "ORBITAL DOCK AUTHORITY", 22, 0xFF9BB4CC));
		add(Gfx.label(20, 230, 500, "FTL ATTENDANT", 52, 0xFFF4F8FC));
		add(Gfx.label(40, 340, 460, "Park fast. Think faster.", 22, 0xFF8AA0B4, false));
		add(Gfx.label(20, 420, 500, 'BEST ${Run.iqText(Run.bestIq())}', 28, 0xFFD6C48A));

		playHit = Gfx.panel(70, 580, 400, 140, 0xCC0C1218);
		add(playHit);
		var play = Gfx.label(70, 580, 400, "ENLIST", 52, 0xFFF4F8FC, false);
		Gfx.centerIn(play, 580, 140);
		add(play);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(playHit))
		{
			Run.reset();
			FlxG.switchState(CutsceneState.new);
		}
	}
}
