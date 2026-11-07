package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class CopyPads extends MiniGame
{
	var pads:Array<FlxSprite> = [];
	var seq:Array<Int>;
	var beat:Float;
	var phase:Int = 0;
	var phaseTime:Float = 0;
	var step:Int = 0;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["COPY", "DO OPPOSITE", "TAP LEFT"];
		super(prompts[rule], speed, rule);
		seq = [FlxG.random.int(0, 1), FlxG.random.int(0, 1)];
		beat = Math.max(0.12, 0.34 / speed);
		var needed = beat * 4 + 0.55;
		if (duration < needed)
		{
			duration = needed;
			timeLeft = needed;
		}

		var left = Gfx.panel(36, 250, 220, 520, 0xFFFFFFFF);
		var right = Gfx.panel(284, 250, 220, 520, 0xFFFFFFFF);
		pads = [left, right];
		add(left);
		add(right);
		paint();
	}

	override function tick(elapsed:Float):Void
	{
		if (phase < 4)
		{
			phaseTime += elapsed;
			if (phaseTime >= beat)
			{
				phaseTime = 0;
				phase++;
			}
		}
		paint();
		if (rule == 2)
		{
			if (!tapped())
				return;
			if (under(pads[0], 8))
				win();
			else if (under(pads[1], 8))
				lose();
			return;
		}
		if (phase < 4 || !tapped())
			return;

		var side = -1;
		if (under(pads[0], 8))
			side = 0;
		else if (under(pads[1], 8))
			side = 1;
		if (side < 0)
			return;
		var expected = rule == 1 ? 1 - seq[step] : seq[step];
		if (side != expected)
		{
			lose();
			return;
		}
		step++;
		if (step >= seq.length)
			win();
	}

	function paint():Void
	{
		var lit = -1;
		if (phase == 0)
			lit = seq[0];
		else if (phase == 2)
			lit = seq[1];
		pads[0].color = lit == 0 ? 0xFFF2C14E : 0xFF3A4158;
		pads[1].color = lit == 1 ? 0xFFF2C14E : 0xFF3A4158;
	}
}
