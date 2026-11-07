package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import fx.Fx;

class WinState extends FlxState
{
	var againHit:FlxSprite;
	var menuHit:FlxSprite;

	override public function create():Void
	{
		Run.boot();
		Fx.mount(this, 1);

		add(Gfx.label(20, 140, 500, "HIRED", 72, 0xFF3DDC97));
		add(Gfx.label(20, 250, 500, "PROBATIONARY", 22, 0xFF9BB4CC));
		add(Gfx.label(20, 290, 500, "FTL PARKING\nATTENDANT", 40, 0xFFF4F8FC));
		add(Gfx.label(20, 450, 500, 'IQ ${Run.iqText(Run.iq)}', 36, 0xFFD6C48A));
		add(Gfx.label(40, 520, 460, "Wave them in. Try not to vaporize the cones.", 22, 0xFF8AA0B4, false));

		againHit = Gfx.panel(70, 620, 400, 110, 0xCC0C1218);
		add(againHit);
		var again = Gfx.label(70, 620, 400, "AGAIN", 40, 0xFFF4F8FC, false);
		Gfx.centerIn(again, 620, 110);
		add(again);

		menuHit = Gfx.panel(70, 760, 400, 100, 0xCC10141C);
		add(menuHit);
		var menu = Gfx.label(70, 760, 400, "MENU", 32, 0xFFF4F8FC, false);
		Gfx.centerIn(menu, 760, 100);
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
