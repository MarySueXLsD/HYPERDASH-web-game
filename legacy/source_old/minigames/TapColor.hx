package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class TapColor extends MiniGame
{
	static var NAMES = ["RED", "BLUE", "YELLOW"];
	static var COLORS = [0xFFE23B4A, 0xFF3C7DFF, 0xFFF2C14E];

	var pick:Int;
	var pads:Array<FlxSprite> = [];

	public function new(speed:Float, rule:Int = 0)
	{
		var pick = FlxG.random.int(0, 2);
		var name = NAMES[pick];
		var prompt = rule == 0 ? 'TAP $name' : rule == 1 ? 'AVOID $name' : "DON'T TAP";
		super(prompt, speed, rule);
		this.pick = pick;

		var order = [0, 1, 2];
		FlxG.random.shuffle(order);
		for (i in 0...3)
		{
			var index = order[i];
			var pad = Gfx.panel(40, 210 + i * 220, 460, 200, COLORS[index]);
			pad.ID = index;
			pads.push(pad);
			add(pad);
		}
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
		for (pad in pads)
		{
			if (!under(pad, 6))
				continue;
			var match = pad.ID == pick;
			if (match == (rule == 0))
				win();
			else
				lose();
			return;
		}
	}

	override function onTimeout():Void
	{
		if (rule == 2)
			win();
		else
			lose();
	}
}
