package fx;

import core.G;
import flixel.FlxSprite;
import flixel.math.FlxMath;

/** Full-screen warp backdrop. Its motion persists across states so cuts feel continuous. */
class Starfield extends FlxSprite
{
	static var travel:Float = 0;
	static var time:Float = 0;
	static var stretchNow:Float = 0.05;
	static var tintA:Array<Float> = [0.1, 0.24, 1.0];
	static var tintB:Array<Float> = [0.24, 0.94, 1.0];

	/** How fast stars fly towards the camera. */
	public var rate:Float = 0.25;

	/** How long the streaks are, 0 = points, 1 = full hyperspace. */
	public var stretch:Float = 0.05;

	public var flash:Float = 0;

	var star:StarShader;
	var wantA:Array<Float>;
	var wantB:Array<Float>;

	public function new()
	{
		super();
		makeGraphic(G.W, G.H, 0xFFFFFFFF);
		star = new StarShader();
		shader = star;
		scrollFactor.set(0, 0);
		wantA = tintA.copy();
		wantB = tintB.copy();
	}

	public function tint(a:Int, b:Int, instant:Bool = false):Void
	{
		wantA = split(a);
		wantB = split(b);
		if (instant)
		{
			tintA = wantA.copy();
			tintB = wantB.copy();
		}
	}

	public function center(x:Float, y:Float):Void
	{
		star.uCenter.value = [x / G.W, y / G.H];
	}

	static function split(c:Int):Array<Float>
	{
		return [((c >> 16) & 0xFF) / 255, ((c >> 8) & 0xFF) / 255, (c & 0xFF) / 255];
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		time += elapsed;
		travel += elapsed * rate;
		stretchNow = FlxMath.lerp(stretchNow, stretch, Math.min(1, elapsed * 4));
		var k = Math.min(1, elapsed * 1.5);
		for (i in 0...3)
		{
			tintA[i] += (wantA[i] - tintA[i]) * k;
			tintB[i] += (wantB[i] - tintB[i]) * k;
		}
		if (flash > 0)
			flash = Math.max(0, flash - elapsed * 3);
		star.uTime.value = [time];
		star.uTravel.value = [travel];
		star.uStretch.value = [stretchNow];
		star.uTintA.value = tintA;
		star.uTintB.value = tintB;
		star.uFlash.value = [flash];
	}
}
