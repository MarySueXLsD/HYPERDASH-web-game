package minigames;

class SwipeLeftLie extends MiniGame
{
	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["SWIPE LEFT", "SWIPE RIGHT", "DON'T SWIPE"];
		super(prompts[rule], speed, rule);
		var arrow = Gfx.arrow("right");
		arrow.x = (Run.W - arrow.width) / 2;
		arrow.y = 280;
		add(arrow);
		add(Gfx.label(40, 520, 460, "RIGHT", 64, 0xFFFFFFFF));
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
		var want = rule == 0 ? "left" : "right";
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
