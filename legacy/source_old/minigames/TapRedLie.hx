package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class TapRedLie extends MiniGame
{
	var pads:Array<FlxSprite> = [];

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP RED", "TAP BLUE", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		var order = [0, 1];
		FlxG.random.shuffle(order);
		var colors = [0xFFE23B4A, 0xFF3C7DFF];
		var lies = ["BLUE", "RED"];
		for (i in 0...2)
		{
			var index = order[i];
			var pad = Gfx.panel(50, 210 + i * 320, 440, 280, colors[index]);
			pad.ID = index;
			pads.push(pad);
			add(pad);
			var caption = Gfx.label(pad.x, pad.y, pad.width, lies[index], 64, 0xFFFFFFFF);
			Gfx.centerIn(caption, pad.y, pad.height);
			add(caption);
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
		for (pad in pads)
		{
			if (!under(pad, 6))
				continue;
			if (pad.ID == rule)
				win();
			else
				lose();
			return;
		}
	}

	override function onTimeout():Void
	{
		if (rule == 2)
			win();
		else
			lose();
	}
}
