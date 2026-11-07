package minigames;

import flixel.FlxSprite;

class LetGoLie extends MiniGame
{
	var fill:FlxSprite;
	var amount:Float = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["LET GO", "HOLD", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		add(Gfx.label(40, 220, 460, "HOLD", 72, 0xFFFFFFFF));
		add(Gfx.panel(70, 400, 400, 48, 0xFF2A2A34));
		fill = Gfx.panel(70, 400, 400, 48, 0xFF3DDC97);
		add(fill);
		Gfx.clipWidth(fill, 400, 0);
		var btn = Gfx.panel(70, 560, 400, 200, 0xFF3DDC97);
		add(btn);
		var caption = Gfx.label(70, 560, 400, "HOLD", 48, 0xFF142018, false);
		Gfx.centerIn(caption, 560, 200);
		add(caption);
	}

	override function tick(elapsed:Float):Void
	{
		if (rule != 2 && holding())
		{
			amount += elapsed / duration;
			Gfx.clipWidth(fill, 400, amount);
		}
		if (rule == 0 && released())
			win();
		else if (rule == 1 && released())
			lose();
		else if (rule == 2 && tapped())
			lose();
	}

	override function onTimeout():Void
	{
		if (rule == 2 || (rule == 1 && holding()))
			win();
		else
			lose();
	}
}
