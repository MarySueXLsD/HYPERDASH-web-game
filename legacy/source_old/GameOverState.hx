package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import fx.Fx;

class GameOverState extends FlxState
{
	var againHit:FlxSprite;
	var menuHit:FlxSprite;

	override public function create():Void
	{
		Run.boot();
		Fx.mount(this, 2);

		add(Gfx.label(20, 150, 500, "REJECTED", 64, 0xFFE23B4A));
		add(Gfx.label(20, 260, 500, "IQ", 24, 0xFF8AA0B4, false));
		add(Gfx.label(20, 300, 500, Run.iqText(Run.iq), 72, 0xFFF4F8FC));
		add(Gfx.label(20, 400, 500, 'BEST ${Run.iqText(Run.bestIq())}', 28, 0xFFD6C48A));
		add(Gfx.label(40, 470, 460, "The bay is closed.", 22, 0xFF8AA0B4, false));

		againHit = Gfx.panel(70, 580, 400, 120, 0xCC0C1218);
		add(againHit);
		var again = Gfx.label(70, 580, 400, "AGAIN", 42, 0xFFF4F8FC, false);
		Gfx.centerIn(again, 580, 120);
		add(again);

		menuHit = Gfx.panel(70, 740, 400, 110, 0xCC10141C);
		add(menuHit);
		var menu = Gfx.label(70, 740, 400, "MENU", 36, 0xFFF4F8FC, false);
		Gfx.centerIn(menu, 740, 110);
		add(menu);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!FlxG.mouse.justPressed)
			return;
		if (FlxG.mouse.overlaps(againHit))
		{
			Run.reset();
			FlxG.switchState(HubState.new);
		}
		else if (FlxG.mouse.overlaps(menuHit))
			FlxG.switchState(MenuState.new);
	}
}
