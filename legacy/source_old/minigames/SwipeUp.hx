package minigames;

import flixel.FlxSprite;

class SwipeUp extends MiniGame
{
	var player:FlxSprite;
	var bar:FlxSprite;
	var vx:Float;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["SWIPE UP", "SWIPE DOWN", "LET IT HIT"];
		super(prompts[rule], speed, rule);
		player = Gfx.person();
		player.x = 225;
		player.y = 560;
		add(player);

		bar = Gfx.panel(-200, 620, 190, 48, 0xFFFFF4E0);
		add(bar);
		vx = (player.x - bar.x) / (duration * 0.72);
	}

	override function tick(elapsed:Float):Void
	{
		bar.x += vx * elapsed;
		var dir = swipe();
		var hits = bar.x < player.x + player.width && bar.x + bar.width > player.x && bar.y < player.y + player.height
			&& bar.y + bar.height > player.y;
		if (rule == 2)
		{
			if (dir != null)
				lose();
			else if (hits)
				win();
			return;
		}
		var want = rule == 0 ? "up" : "down";
		if (dir == want)
		{
			player.y = rule == 0 ? 360 : 760;
			win();
			return;
		}
		if (dir != null || hits)
			lose();
	}
}
