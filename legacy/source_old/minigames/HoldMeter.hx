package minigames;

import flixel.FlxSprite;

class HoldMeter extends MiniGame
{
	var fill:FlxSprite;
	var amount:Float = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["HOLD", "TAP", "DON'T HOLD"];
		super(prompts[rule], speed, rule);
		add(Gfx.panel(70, 300, 400, 48, 0xFF2A2A34));
		fill = Gfx.panel(70, 300, 400, 48, 0xFFF2C14E);
		add(fill);
		Gfx.clipWidth(fill, 400, 0);

		var btn = Gfx.panel(70, 520, 400, 200, 0xFF3DDC97);
		add(btn);
		var caption = Gfx.label(70, 520, 400, "HOLD", 48, 0xFF142018, false);
		Gfx.centerIn(caption, 520, 200);
		add(caption);
	}

	override function tick(elapsed:Float):Void
	{
		if (rule == 1)
		{
			if (tapped())
				win();
			return;
		}
		if (rule == 2)
		{
			if (tapped())
				lose();
			return;
		}
		if (holding())
			amount += elapsed / (duration * 0.82);
		if (amount >= 1)
		{
			amount = 1;
			Gfx.clipWidth(fill, 400, 1);
			win();
			return;
		}
		if (released() && amount > 0)
		{
			lose();
			return;
		}
		Gfx.clipWidth(fill, 400, amount);
	}

	override function onTimeout():Void
	{
		if (rule == 2)
			win();
		else
			lose();
	}
}
