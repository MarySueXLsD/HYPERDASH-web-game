package fx;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;

class Fx
{
	public static var time:Float = 0;

	static var _light:LightShader;

	public static var light(get, never):LightShader;

	public static function mount(state:FlxState, style:Int):Void
	{
		state.bgColor = 0xFF05040C;
		FlxG.camera.bgColor = 0xFF05040C;
		state.add(new PlasmaBackdrop(style));
	}

	public static function tick(elapsed:Float, plasma:PlasmaShader):Void
	{
		time += elapsed;
		plasma.uTime.value[0] = time;
	}

	static function get_light():LightShader
	{
		if (_light == null)
			_light = new LightShader();
		return _light;
	}
}

class PlasmaBackdrop extends FlxSprite
{
	var plasma:PlasmaShader;

	public function new(style:Int)
	{
		super();
		makeGraphic(Run.W, Run.H, 0xFFFFFFFF);
		plasma = new PlasmaShader();
		plasma.uStyle.value = [style];
		shader = plasma;
		scrollFactor.set(0, 0);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		Fx.tick(elapsed, plasma);
	}
}
