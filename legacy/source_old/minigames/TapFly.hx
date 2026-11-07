package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class TapFly extends MiniGame
{
	var fly:FlxSprite;
	var vx:Float;
	var vy:Float;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP THE FLY", "DON'T TAP", "TAP THE GAP"];
		super(prompts[rule], speed, rule);
		fly = Gfx.fly();
		fly.x = FlxG.random.float(40, 400);
		fly.y = FlxG.random.float(230, 700);
		add(fly);

		var pace = Math.min(speed, 3.2);
		vx = FlxG.random.float(140, 220) * pace * (FlxG.random.bool() ? 1 : -1);
		vy = FlxG.random.float(100, 180) * pace * (FlxG.random.bool() ? 1 : -1);
	}

	override function tick(elapsed:Float):Void
	{
		fly.x += vx * elapsed;
		fly.y += vy * elapsed;
		if (fly.x < 24)
		{
			fly.x = 24;
			vx = Math.abs(vx);
		}
		else if (fly.x > Run.W - 24 - fly.width)
		{
			fly.x = Run.W - 24 - fly.width;
			vx = -Math.abs(vx);
		}
		if (fly.y < 200)
		{
			fly.y = 200;
			vy = Math.abs(vy);
		}
		else if (fly.y > 880 - fly.height)
		{
			fly.y = 880 - fly.height;
			vy = -Math.abs(vy);
		}
		if (!tapped())
			return;
		var hit = under(fly, 28);
		if (rule == 0)
		{
			if (hit)
				win();
		}
		else if (rule == 1)
			lose();
		else if (hit)
			lose();
		else
			win();
	}

	override function onTimeout():Void
	{
		if (rule == 1)
			win();
		else
			lose();
	}
}
