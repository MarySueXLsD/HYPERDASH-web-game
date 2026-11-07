package minigames;

import flixel.text.FlxText;

class ExactTaps extends MiniGame
{
	var need:Int;
	var count:Int = 0;
	var number:FlxText;

	public function new(speed:Float, rule:Int = 0)
	{
		var need = Run.timeLimit() < 1.1 ? 2 : 3;
		var prompt = rule == 0 ? 'TAP $need TIMES' : rule == 1 ? "TAP ONCE" : "DON'T TAP";
		super(prompt, speed, rule);
		this.need = need;
		number = Gfx.label(0, 360, Run.W, Std.string(need), 160, 0xFFFFFFFF);
		add(number);
	}

	override function tick(elapsed:Float):Void
	{
		if (!tapped())
			return;
		if (rule == 2)
		{
			lose();
			return;
		}
		count++;
		if (rule == 0)
			number.text = Std.string(need - count);
		var limit = rule == 1 ? 1 : need;
		if (count > limit)
			lose();
	}

	override function onTimeout():Void
	{
		var goal = rule == 1 ? 1 : need;
		if (rule == 2 || (rule != 2 && count == goal))
			win();
		else
			lose();
	}
}
