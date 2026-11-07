package minigames;

import flixel.FlxG;
import flixel.FlxSprite;

class TapCircle extends MiniGame
{
	var circle:FlxSprite;
	var square:FlxSprite;

	public function new(speed:Float, rule:Int = 0)
	{
		var prompts = ["TAP CIRCLE", "TAP SQUARE", "TAP EITHER"];
		super(prompts[rule], speed, rule);
		var circleLeft = FlxG.random.bool();
		square = Gfx.panel(circleLeft ? 300 : 40, 380, 200, 200, 0xFF3C7DFF);
		circle = Gfx.circle(200, 0xFFF2C14E);
		circle.x = circleLeft ? 40 : 300;
		circle.y = 380;
		add(square);
		add(circle);
		var squareWord = Gfx.label(square.x, square.y, square.width, "CIRCLE", 32, 0xFFFFFFFF);
		Gfx.centerIn(squareWord, square.y, square.height);
		add(squareWord);
		var circleWord = Gfx.label(circle.x, circle.y, circle.width, "SQUARE", 32, 0xFF142018, false);
		Gfx.centerIn(circleWord, circle.y, circle.height);
		add(circleWord);
	}

	override function tick(elapsed:Float):Void
	{
		if (!tapped())
			return;
		var onCircle = under(circle, 8);
		var onSquare = under(square, 8);
		if (rule == 2)
		{
			if (onCircle || onSquare)
				win();
			return;
		}
		if (rule == 0 && onCircle)
			win();
		else if (rule == 1 && onSquare)
			win();
		else if (onCircle || onSquare)
			lose();
	}
}
