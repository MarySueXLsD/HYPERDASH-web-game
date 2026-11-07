package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class SmileSkull extends MiniGame
{
	var smile:FlxSprite;
	var skull:FlxSprite;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP THE SMILE", "TAP THE SKULL", "DON'T TAP"];
		super(prompts[rule], speed, rule);
		var smileLeft = FlxG.random.bool();
		smile = Gfx.face(true);
		skull = Gfx.face(false);
		smile.y = skull.y = 360;
		smile.x = smileLeft ? 40 : 290;
		skull.x = smileLeft ? 290 : 40;
		add(smile);
		add(skull);
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
		var target = rule == 0 ? smile : skull;
		var other = rule == 0 ? skull : smile;
		if (under(target, 8))
			win();
		else if (under(other, 8))
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
