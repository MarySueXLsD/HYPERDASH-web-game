package minigames;

import flixel.FlxSprite;

class KeepUp extends MiniGame
{
	var bubble:FlxSprite;
	var vy:Float = 0;
	var k:Float;
	var bandTop:Float = 450;
	var bandBottom:Float = 690;
	var taps:Int = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["KEEP IT UP", "LET IT FALL", "TAP ONCE"];
		super(prompts[rule], speed, rule);
		k = Math.sqrt(speed);
		add(Gfx.panel(30, bandTop, 480, Std.int(bandBottom - bandTop), 0x443DDC97));
		add(Gfx.panel(30, bandTop, 480, 8, 0xFF3DDC97));
		add(Gfx.panel(30, bandBottom - 8, 480, 8, 0xFF3DDC97));
		bubble = Gfx.circle(76, 0xFF7AD7FF);
		bubble.x = (Run.W - bubble.width) / 2;
		bubble.y = (bandTop + bandBottom) / 2 - bubble.height / 2;
		add(bubble);
	}

	override function tick(elapsed:Float):Void
	{
		if (rule == 2 && tapped())
		{
			taps++;
			if (taps > 1)
			{
				lose();
				return;
			}
		}
		if (rule == 1 && tapped())
		{
			lose();
			return;
		}
		if (rule == 0 && tapped())
			vy = -620 * k;
		vy += 1400 * k * elapsed;
		bubble.y += vy * elapsed;
		var cy = bubble.y + bubble.height / 2;
		if (rule == 2)
			return;
		if (rule == 1 && cy > 920)
			win();
		else if (cy < 180 || cy > 920)
			lose();
	}

	override function onTimeout():Void
	{
		if (rule == 2)
		{
			if (taps == 1)
				win();
			else
				lose();
			return;
		}
		if (rule != 0)
		{
			lose();
			return;
		}
		var cy = bubble.y + bubble.height / 2;
		if (cy >= bandTop && cy <= bandBottom)
			win();
		else
			lose();
	}
}
