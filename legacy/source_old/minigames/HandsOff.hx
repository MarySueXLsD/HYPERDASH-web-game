package minigames;

import flixel.FlxSprite;

class HandsOff extends MiniGame
{
	var btn:FlxSprite;
	var pulse:Float = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["DON'T TAP", "TAP", "HOLD"];
		super(prompts[rule], speed, rule);
		btn = Gfx.circle(240, 0xFFE23B4A);
		btn.origin.set(btn.width / 2, btn.height / 2);
		btn.x = (Run.W - btn.width) / 2;
		btn.y = 430;
		add(btn);
		var bait = Gfx.label(btn.x, btn.y, btn.width, "TAP", 48, 0xFFFFFFFF);
		Gfx.centerIn(bait, btn.y, btn.height);
		add(bait);
	}

	override function tick(elapsed:Float):Void
	{
		pulse += elapsed;
		btn.scale.set(1 + 0.07 * Math.sin(pulse * 7), 1 + 0.07 * Math.sin(pulse * 7));
		if (rule == 0 && tapped())
			lose();
		else if (rule == 1 && tapped())
			win();
		else if (rule == 2 && released())
			lose();
	}

	override function onTimeout():Void
	{
		if (rule == 0 || (rule == 2 && holding()))
			win();
		else
			lose();
	}
}
