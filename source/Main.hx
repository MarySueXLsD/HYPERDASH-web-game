package;

import core.G;
import flixel.FlxGame;
import openfl.display.Sprite;
import states.BootState;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(G.W, G.H, BootState.new, 60, 60, true));
	}
}
