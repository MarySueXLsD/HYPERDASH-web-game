package minigames;

import flixel.FlxSprite;

class TapSmall extends MiniGame
{
	var huge:FlxSprite;
	var small:FlxSprite;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP SMALL", "TAP BIG", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		huge = Gfx.panel(40, 200, 460, 500, 0xFF3DDC97);
		add(huge);
		var bait = Gfx.label(huge.x, huge.y, huge.width, "TAP ME", 64, 0xFF142018, false);
		Gfx.centerIn(bait, huge.y, huge.height);
		add(bait);

		small = Gfx.panel(235, 760, 70, 70, 0xFFF2C14E);
		add(small);
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
		if (rule == 0 && under(small, 16))
			win();
		else if (rule == 1 && under(huge, 0))
			win();
		else if (rule == 0 && under(huge, 0))
			lose();
		else if (rule == 1 && under(small, 16))
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
