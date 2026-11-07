package minigames;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

class LetFall extends MiniGame
{
	var item:FlxSprite;
	var bait:FlxText;
	var vy:Float;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["LET IT FALL", "CATCH", "TAP BESIDE"];
		super(prompts[rule], speed, rule);
		item = Gfx.coin();
		item.x = FlxG.random.float(30, Run.W - 30 - item.width);
		item.y = 200;
		add(item);
		bait = Gfx.label(item.x, item.y, item.width, "CATCH", 28, 0xFF142018, false);
		Gfx.centerIn(bait, item.y, item.height);
		add(bait);
		vy = (860 - item.y) / (duration * 0.88);
	}

	override function tick(elapsed:Float):Void
	{
		item.y += vy * elapsed;
		bait.y = item.y + (item.height - bait.height) / 2;
		var onCoin = tapped() && under(item, 24);
		if (rule == 0)
		{
			if (onCoin)
				lose();
			else if (item.y > 860)
				win();
		}
		else if (rule == 1)
		{
			if (onCoin)
				win();
			else if (item.y > 860)
				lose();
		}
		else if (tapped() && FlxG.mouse.y >= 190)
		{
			if (onCoin)
				lose();
			else
				win();
		}
		else if (item.y > 860)
			lose();
	}

	override function onTimeout():Void
	{
		if (rule == 0)
			win();
		else
			lose();
	}
}
