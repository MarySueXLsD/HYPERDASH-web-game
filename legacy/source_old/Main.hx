package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(Run.W, Run.H, MenuState.new, 60, 60, true));
	}
}
