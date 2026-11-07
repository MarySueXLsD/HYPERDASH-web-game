package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Spin your finger around the wheel to wind the backup generator. */
class Crank extends Micro
{
	static inline var CX:Float = 270;
	static inline var CY:Float = 490;
	static inline var LIGHTS:Int = 16;

	var wheel:FlxSprite;
	var knob:FlxSprite;
	var lights:Array<FlxSprite> = [];
	var cum:Float = 0;
	var need:Float;
	var lastA:Float = 0;
	var tracking:Bool = false;
	var lastClick:Int = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [8, 9, 10][level]);
	}

	override function setup():Void
	{
		// The fuse shortens with warp, but hands only get so fast.
		need = Math.PI * 2 * [2, 3, 4][level] / (1 + (speed - 1) * 0.5);
		for (i in 0...LIGHTS)
		{
			var a = i / LIGHTS * Math.PI * 2 - Math.PI / 2;
			var l = Art.sprite("cranklight", 26, 26, function(g)
			{
				Art.fill(g, 0xFFFFFF);
				Art.line(g, 3, G.INK);
				g.drawCircle(13, 13, 10);
				g.endFill();
			}, 0);
			l.color = 0xFF5A5468;
			Art.center(l, CX + Math.cos(a) * 210, CY + Math.sin(a) * 210);
			lights.push(l);
			add(l);
		}
		wheel = Art.sprite("crankwheel", 340, 340, function(g)
		{
			Art.fill(g, 0x2B2440);
			Art.line(g, 8, G.KRAFT);
			g.drawCircle(170, 170, 160);
			g.endFill();
			Art.line(g, 10, G.KRAFT);
			for (i in 0...3)
			{
				var a = i * Math.PI / 3;
				Art.poly(g, [170 - Math.cos(a) * 156, 170 - Math.sin(a) * 156, 170 + Math.cos(a) * 156, 170 + Math.sin(a) * 156], false);
			}
			g.lineStyle();
			Art.fill(g, G.ORANGE);
			g.drawCircle(170, 170, 30);
			g.endFill();
		}, 0);
		Art.center(wheel, CX, CY);
		add(wheel);
		knob = Art.sprite("crankknob", 70, 70, function(g)
		{
			Art.fill(g, G.CYAN);
			Art.line(g, 4, G.INK);
			g.drawCircle(35, 35, 30);
			g.endFill();
		}, 1, 6);
		add(knob);
		place();
	}

	function place():Void
	{
		wheel.angle = cum * 180 / Math.PI;
		var a = cum - Math.PI / 2;
		Art.center(knob, CX + Math.cos(a) * 130, CY + Math.sin(a) * 130);
		var lit = Std.int(Math.abs(cum) / need * LIGHTS);
		for (i in 0...LIGHTS)
			lights[i].color = i < lit ? G.GREEN : 0xFF5A5468;
	}

	function spin(delta:Float):Void
	{
		cum += delta;
		var click = Std.int(Math.abs(cum) / (Math.PI / 4));
		if (click != lastClick)
		{
			lastClick = click;
			Audio.sfx("charge", 0.7 + Math.abs(cum) / need * 1.4);
			fx.puff(Art.cx(knob), Art.cy(knob), G.CYAN, FlxG.random.float(-80, 80), FlxG.random.float(-80, 80), 0.4, 0.3);
		}
	}

	override function tick(elapsed:Float):Void
	{
		if (live())
		{
			if (FlxG.mouse.pressed && Micro.dist(px, py, CX, CY) > 36)
			{
				var a = Math.atan2(py - CY, px - CX);
				if (tracking)
				{
					var d = a - lastA;
					while (d > Math.PI)
						d -= Math.PI * 2;
					while (d < -Math.PI)
						d += Math.PI * 2;
					// A jump this big is a re-grip, not a spin.
					if (Math.abs(d) < 1.6)
						spin(d);
				}
				lastA = a;
				tracking = true;
			}
			else
				tracking = false;
			if (FlxG.keys.justPressed.SPACE)
				spin(Math.PI / 2);
			if (Math.abs(cum) >= need)
			{
				Audio.sfx("locked");
				cheer(CX, CY);
				for (l in lights)
					l.color = G.GREEN;
				win();
			}
		}
		else if (finished && won)
			wheel.angle += elapsed * 720;
		if (live())
			place();
	}
}
