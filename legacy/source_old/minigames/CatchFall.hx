package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class CatchFall extends MiniGame
{
	var item:FlxSprite;
	var vy:Float;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["CATCH", "LET IT FALL", "TAP IT HIGH"];
		super(prompts[rule], speed, rule);
		item = Gfx.coin();
		item.x = FlxG.random.float(30, Run.W - 30 - item.width);
		item.y = 190;
		add(item);
		vy = (860 - item.y) / (duration * 0.88);
	}

	override function tick(elapsed:Float):Void
	{
		item.y += vy * elapsed;
		var caught = tapped() && under(item, 30);
		if (rule == 0)
		{
			if (caught)
				win();
			else if (item.y > 880)
				lose();
		}
		else if (rule == 1)
		{
			if (caught)
				lose();
			else if (item.y > 880)
				win();
		}
		else if (caught)
		{
			if (item.y < 480)
				win();
			else
				lose();
		}
		else if (item.y > 880)
			lose();
	}

	override function onTimeout():Void
	{
		if (rule == 1)
			win();
		else
			lose();
	}
}
