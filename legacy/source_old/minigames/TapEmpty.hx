package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class TapEmpty extends MiniGame
{
	var empty:FlxSprite;
	var full:FlxSprite;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP EMPTY", "TAP THE WORD", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		var emptyLeft = FlxG.random.bool();
		empty = Gfx.panel(emptyLeft ? 30 : 280, 280, 230, 460, 0xFF2A2E38);
		full = Gfx.panel(emptyLeft ? 280 : 30, 280, 230, 460, 0xFF3DDC97);
		add(empty);
		add(full);
		for (i in 0...4)
		{
			var word = Gfx.label(full.x, full.y + 40 + i * 100, full.width, "TAP", 42, 0xFF142018, false);
			add(word);
		}
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
		if (rule == 0 && under(empty, 8))
			win();
		else if (rule == 1 && under(full, 8))
			win();
		else if (rule == 0 && under(full, 8))
			lose();
		else if (rule == 1 && under(empty, 8))
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
