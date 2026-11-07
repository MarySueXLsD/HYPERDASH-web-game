package minigames;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

class MiniGame extends FlxGroup
{
	public var prompt:String;
	public var rule:Int;
	public var done:Bool = false;
	public var won:Bool = false;
	public var timeLeft:Float;
	public var duration:Float;

	var speed:Float;
	var armed:Bool = false;

	public function new(prompt:String, speed:Float, rule:Int = 0)
	{
		super();
		this.prompt = prompt;
		this.rule = rule;
		this.speed = speed;
		duration = prompt == "DON'T TAP" ? Run.dontTapLimit() : Run.timeLimit();
		timeLeft = duration;
	}

	override public function update(elapsed:Float):Void
	{
		if (done)
			return;

		if (!armed)
		{
			if (!FlxG.mouse.pressed && swipe() == null)
				armed = true;
			return;
		}

		super.update(elapsed);
		tick(elapsed);
		if (done)
			return;

		timeLeft -= elapsed;
		if (timeLeft <= 0)
			onTimeout();
	}

	function tick(elapsed:Float):Void {}

	function onTimeout():Void
	{
		lose();
	}

	function win():Void
	{
		if (done)
			return;
		done = true;
		won = true;
	}

	function lose():Void
	{
		if (done)
			return;
		done = true;
		won = false;
	}

	function tapped():Bool
	{
		return FlxG.mouse.justPressed;
	}

	function released():Bool
	{
		return FlxG.mouse.justReleased;
	}

	function holding():Bool
	{
		return FlxG.mouse.pressed;
	}

	function swipe():Null<String>
	{
		if (FlxG.swipes == null || FlxG.swipes.length == 0)
			return null;
		var last = FlxG.swipes[FlxG.swipes.length - 1];
		var dx = last.endPosition.x - last.startPosition.x;
		var dy = last.endPosition.y - last.startPosition.y;
		if (dx * dx + dy * dy < 40 * 40)
			return null;
		if (Math.abs(dx) > Math.abs(dy))
			return dx > 0 ? "right" : "left";
		return dy > 0 ? "down" : "up";
	}

	function under(sprite:FlxSprite, pad:Float = 20):Bool
	{
		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;
		return mx >= sprite.x - pad && mx <= sprite.x + sprite.width + pad && my >= sprite.y - pad && my <= sprite.y + sprite.height + pad;
	}
}
