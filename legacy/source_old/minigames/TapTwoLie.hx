package minigames;

class TapTwoLie extends MiniGame
{
	var count:Int = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP 2", "TAP 5", "TAP ONCE"];
		super(prompts[rule], speed, rule);
		if (rule == 1 && duration < 1.8)
		{
			duration = 1.8;
			timeLeft = 1.8;
		}
		add(Gfx.label(0, 340, Run.W, "5", 180, 0xFFFFFFFF));
	}

	override function tick(elapsed:Float):Void
	{
		if (!tapped())
			return;
		count++;
		var need = rule == 2 ? 1 : rule == 0 ? 2 : 5;
		if (count > need)
			lose();
	}

	override function onTimeout():Void
	{
		var need = rule == 2 ? 1 : rule == 0 ? 2 : 5;
		if (count == need)
			win();
		else
			lose();
	}
}
