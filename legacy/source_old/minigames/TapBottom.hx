package minigames;

import flixel.FlxSprite;

class TapBottom extends MiniGame
{
	var top:FlxSprite;
	var bottom:FlxSprite;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP BOTTOM", "TAP TOP", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		top = Gfx.panel(40, 200, 460, 360, 0xFF3DDC97);
		add(top);
		var correct = Gfx.label(top.x, top.y, top.width, "CORRECT", 52, 0xFF142018, false);
		Gfx.centerIn(correct, top.y, top.height);
		add(correct);

		bottom = Gfx.panel(70, 640, 400, 180, 0xFF2A2E38);
		add(bottom);
		var wrong = Gfx.label(bottom.x, bottom.y, bottom.width, "WRONG", 42, 0xFF8E97A6, false);
		Gfx.centerIn(wrong, bottom.y, bottom.height);
		add(wrong);
	}

	override function tick(elapsed:Float):Void
	{
		if (rule == 2)
		{
			if (tapped())
				lose();
			return;
		}
		if (!tapped())
			return;
		if (rule == 0 && under(bottom, 8))
			win();
		else if (rule == 1 && under(top, 8))
			win();
		else if (rule == 0 && under(top, 8))
			lose();
		else if (rule == 1 && under(bottom, 8))
			lose();
	}

	override function onTimeout():Void
	{
		if (rule == 2)
			win();
		else
			lose();
	}
}
