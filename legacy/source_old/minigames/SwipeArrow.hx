package minigames;

import flixel.FlxG;

class SwipeArrow extends MiniGame
{
	var dir:String;
	var want:String;

	public function new(speed:Float, rule:Int = 0)
	{
		var dirs = ["up", "down", "left", "right"];
		dir = dirs[FlxG.random.int(0, dirs.length - 1)];
		var opposite = dir == "up" ? "down" : dir == "down" ? "up" : dir == "left" ? "right" : "left";
		want = rule == 1 ? opposite : dir;
		var prompt = rule == 2 ? "DON'T SWIPE" : 'SWIPE ${want.toUpperCase()}';
		super(prompt, speed, rule);

		var arrow = Gfx.arrow(dir);
		arrow.x = (Run.W - arrow.width) / 2;
		arrow.y = 360;
		add(arrow);
	}

	override function tick(elapsed:Float):Void
	{
		var got = swipe();
		if (got == null)
			return;
		if (rule == 2)
		{
			lose();
			return;
		}
		if (got == want)
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
