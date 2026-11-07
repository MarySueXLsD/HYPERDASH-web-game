package minigames;

import flixel.FlxSprite;

class StopZone extends MiniGame
{
	var marker:FlxSprite;
	var clock:Float = 0;
	var period:Float;
	var greenX:Float;
	var greenW:Float;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP IN THE GREEN", "TAP THE DARK", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		add(Gfx.panel(40, 470, 460, 48, 0xFF2A2A34));
		greenW = 120;
		greenX = 40 + (460 - greenW) / 2;
		add(Gfx.panel(greenX, 470, Std.int(greenW), 48, 0xFF3DDC97));
		marker = Gfx.panel(40, 448, 34, 92, 0xFFFFFFFF);
		add(marker);
		period = Math.max(0.45, 1.25 / speed);
	}

	override function tick(elapsed:Float):Void
	{
		clock += elapsed;
		var p = (Math.sin(clock / period * Math.PI * 2 - Math.PI / 2) + 1) / 2;
		marker.x = 40 + p * (460 - marker.width);
		if (rule == 2)
		{
			if (tapped())
				lose();
			return;
		}
		if (!tapped())
			return;
		var cx = marker.x + marker.width / 2;
		var inGreen = cx >= greenX && cx <= greenX + greenW;
		if (inGreen == (rule == 0))
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
