package minigames;

import flixel.FlxSprite;
import flixel.text.FlxText;

class TapOnStop extends MiniGame
{
	var sign:FlxSprite;
	var word:FlxText;
	var stopFor:Float;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP STOP", "TAP GO", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		stopFor = Math.max(0.22, 0.48 / speed);
		sign = Gfx.panel(50, 300, 440, 360, 0xFF3DDC97);
		add(sign);
		word = Gfx.label(sign.x, sign.y, sign.width, "GO", 92, 0xFF142018, false);
		Gfx.centerIn(word, sign.y, sign.height);
		add(word);
	}

	override function tick(elapsed:Float):Void
	{
		var stop = timeLeft <= stopFor;
		sign.color = stop ? 0xFFE23B4A : 0xFFFFFFFF;
		word.text = stop ? "STOP" : "GO";
		word.color = stop ? 0xFFFFFFFF : 0xFF142018;
		Gfx.centerIn(word, sign.y, sign.height);
		if (!tapped())
			return;
		if (rule == 2)
		{
			lose();
			return;
		}
		if (stop == (rule == 0))
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
