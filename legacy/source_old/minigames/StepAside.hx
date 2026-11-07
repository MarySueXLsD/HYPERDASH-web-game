package minigames;

import flixel.FlxG;

class StepAside extends MiniGame
{
	var safeLeft:Bool;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP THE SAFE SIDE", "TAP THE ROCK", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		safeLeft = FlxG.random.bool();
		add(Gfx.panel(16, 200, 250, 720, safeLeft ? 0xFF1C3D2E : 0xFF3D1C24));
		add(Gfx.panel(274, 200, 250, 720, safeLeft ? 0xFF3D1C24 : 0xFF1C3D2E));

		var rock = Gfx.circle(180, 0xFF8A8A96);
		rock.x = (safeLeft ? 274 : 16) + (250 - rock.width) / 2;
		rock.y = 430;
		add(rock);

		var safeX = safeLeft ? 16 : 274;
		var caption = Gfx.label(safeX, 300, 250, "SAFE", 42, 0xFF3DDC97);
		add(caption);
	}

	override function tick(elapsed:Float):Void
	{
		if (rule == 2)
		{
			if (tapped())
				lose();
			return;
		}
		if (!tapped())
			return;
		var left = FlxG.mouse.x < Run.W / 2;
		var wantLeft = rule == 0 ? safeLeft : !safeLeft;
		if (left == wantLeft)
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
