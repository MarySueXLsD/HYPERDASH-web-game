package minigames;

import flixel.FlxSprite;

class TapRightIgnore extends MiniGame
{
	var pads:Array<FlxSprite> = [];
	var clock:Float = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP RIGHT", "TAP LEFT", "FOLLOW THE FLASH"];
		super(prompts[rule], speed, rule);
		add(Gfx.label(20, 190, 500, "FOLLOW THE FLASH", 32, 0xFFF2C14E));
		var left = Gfx.panel(36, 270, 220, 520, 0xFFFFFFFF);
		var right = Gfx.panel(284, 270, 220, 520, 0xFFFFFFFF);
		pads = [left, right];
		add(left);
		add(right);
	}

	override function tick(elapsed:Float):Void
	{
		clock += elapsed;
		var beat = Math.max(0.12, 0.28 / speed);
		var lit = Std.int(Math.floor(clock / beat)) % 2;
		pads[0].color = lit == 0 ? 0xFFF2C14E : 0xFF3A4158;
		pads[1].color = lit == 1 ? 0xFFF2C14E : 0xFF3A4158;
		if (!tapped())
			return;
		var right = under(pads[1], 8);
		var left = under(pads[0], 8);
		if (rule == 2)
		{
			if (right && lit == 1)
				win();
			else if (left && lit == 0)
				win();
			else if (left || right)
				lose();
			return;
		}
		if (rule == 0 && right)
			win();
		else if (rule == 1 && left)
			win();
		else if (left || right)
			lose();
	}
}
