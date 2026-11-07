package minigames;

import flixel.FlxSprite;

class LetGo extends MiniGame
{
	var marker:FlxSprite;
	var green:FlxSprite;
	var top:Float;
	var bottom:Float;
	var progress:Float = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["LET GO IN GREEN", "MISS THE GREEN", "KEEP HOLDING"];
		super(prompts[rule], speed, rule);
		add(Gfx.panel(258, 210, 24, 640, 0xFF2A2A34));
		green = Gfx.panel(230, 210 + 640 * 0.36, 80, Std.int(640 * 0.28), 0xFF3DDC97);
		add(green);
		marker = Gfx.circle(72, 0xFFF2C14E);
		marker.x = 234;
		top = 210;
		bottom = 210 + 640 - marker.height;
		marker.y = bottom;
		add(marker);
	}

	override function tick(elapsed:Float):Void
	{
		progress += elapsed / (duration * 0.92);
		if (progress > 1)
			progress = 1;
		marker.y = bottom - progress * (bottom - top);
		if (rule == 2)
		{
			if (released())
				lose();
			return;
		}
		if (!released())
			return;
		var cy = marker.y + marker.height / 2;
		var inGreen = cy >= green.y && cy <= green.y + green.height;
		if (inGreen == (rule == 0))
			win();
		else
			lose();
	}

	override function onTimeout():Void
	{
		if (rule == 2 && holding())
			win();
		else
			lose();
	}
}
