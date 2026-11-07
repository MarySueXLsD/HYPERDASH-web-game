package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class TapDark extends MiniGame
{
	var bright:FlxSprite;
	var dark:FlxSprite;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP DARK", "TAP BRIGHT", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		var brightTop = FlxG.random.bool();
		bright = Gfx.panel(50, brightTop ? 210 : 560, 440, 250, 0xFFFFF6E4);
		dark = Gfx.panel(50, brightTop ? 560 : 210, 440, 250, 0xFF2C3140);
		add(bright);
		add(dark);
		var bait = Gfx.label(bright.x, bright.y, bright.width, "TAP", 64, 0xFF142018, false);
		Gfx.centerIn(bait, bright.y, bright.height);
		add(bait);
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
		if (rule == 0 && under(dark, 8))
			win();
		else if (rule == 1 && under(bright, 8))
			win();
		else if (under(dark, 8) || under(bright, 8))
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
