package minigames;

import flixel.FlxSprite;
import flixel.text.FlxText;

class WaitGreen extends MiniGame
{
	var light:FlxSprite;
	var word:FlxText;
	var greenFor:Float;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["WAIT FOR GREEN", "TAP THE RED", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		greenFor = Math.max(0.22, 0.48 / speed);
		light = Gfx.circle(300, 0xFFFFFFFF);
		light.x = (Run.W - light.width) / 2;
		light.y = 310;
		light.color = 0xFFE23B4A;
		add(light);
		word = Gfx.label(light.x, light.y, light.width, "WAIT", 64, 0xFF142018, false);
		Gfx.centerIn(word, light.y, light.height);
		add(word);
	}

	override function tick(elapsed:Float):Void
	{
		var green = timeLeft <= greenFor;
		light.color = green ? 0xFF3DDC97 : 0xFFE23B4A;
		word.text = green ? "NOW" : "WAIT";
		Gfx.centerIn(word, light.y, light.height);
		if (rule == 2)
		{
			if (tapped())
				lose();
			return;
		}
		if (!tapped())
			return;
		if (green == (rule == 0))
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
