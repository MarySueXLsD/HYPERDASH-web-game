package core;

import flixel.FlxG;
import openfl.events.MouseEvent;

/**
 * Latches presses straight from the stage so a tap that starts and ends
 * within a single frame is never lost (FlxMouse alone would drop it).
 */
class Input
{
	public static var justPressed(get, never):Bool;
	public static var justReleased(get, never):Bool;

	static var down:Bool = false;
	static var up:Bool = false;
	static var ready:Bool = false;

	public static function init():Void
	{
		if (ready)
			return;
		ready = true;
		FlxG.stage.addEventListener(MouseEvent.MOUSE_DOWN, function(_) down = true);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_UP, function(_) up = true);
		FlxG.signals.postUpdate.add(function()
		{
			down = false;
			up = false;
		});
	}

	static function get_justPressed():Bool
	{
		return down || FlxG.mouse.justPressed;
	}

	static function get_justReleased():Bool
	{
		return up || FlxG.mouse.justReleased;
	}
}
