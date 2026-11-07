package minigames;

import flixel.FlxG;

class TapLeftLie extends MiniGame
{
	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP LEFT", "TAP RIGHT", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		add(Gfx.panel(16, 200, 250, 720, 0xFF2A2E38));
		add(Gfx.panel(274, 200, 250, 720, 0xFFF2C14E));
		var no = Gfx.label(16, 480, 250, "NO", 64, 0xFF8E97A6, false);
		add(no);
		var yes = Gfx.label(274, 480, 250, "YES", 64, 0xFF142018, false);
		add(yes);
	}

	override function tick(elapsed:Float):Void
	{
		if (rule == 2)
		{
			if (tapped() && FlxG.mouse.y >= 190)
				lose();
			return;
		}
		if (!tapped())
			return;
		if (FlxG.mouse.y < 190)
			return;
		var left = FlxG.mouse.x < Run.W / 2;
		if (left == (rule == 0))
			win();
		else
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
