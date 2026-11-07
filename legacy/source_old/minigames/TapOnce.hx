package minigames;

class TapOnce extends MiniGame
{
	var count:Int = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP ONCE", "TAP 5 TIMES", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		if (rule == 1 && duration < 1.8)
		{
			duration = 1.8;
			timeLeft = 1.8;
		}
		add(Gfx.label(20, 360, 500, "TAP 5 TIMES", 52, 0xFFFFFFFF));
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
		var limit = rule == 0 ? 1 : 5;
		if (count > limit)
			lose();
	}

	override function onTimeout():Void
	{
		var need = rule == 0 ? 1 : 5;
		if (rule == 2 || (rule != 2 && count == need))
			win();
		else
			lose();
	}
}
