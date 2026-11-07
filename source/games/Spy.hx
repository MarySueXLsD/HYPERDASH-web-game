package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;
import openfl.display.Graphics;

/** A fleet of identical ships hides one impostor. Tap it. */
class Spy extends Micro
{
	var ships:Array<FlxSprite> = [];
	var spy:FlxSprite;
	var t:Float = 0;
	var cols:Int = 3;
	var rows:Int;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [6, 7, 8][level]);
	}

	static function hull(g:Graphics, variant:Int):Void
	{
		Art.fill(g, 0x1A2040);
		Art.line(g, 3, 0xFFFFFF);
		var wing = variant == 1 ? 18.0 : (variant == 2 ? 6.0 : 0.0);
		Art.poly(g, [36, 0, 46, 26, 52, 46, 72 - wing, 70, 72 - wing, 84, 50, 80, 22, 80, 0 + wing, 84, 0 + wing, 70, 20, 46, 26, 26]);
		g.endFill();
		if (variant != 1)
		{
			g.lineStyle();
			Art.fill(g, 0xFFFFFF);
			g.drawEllipse(30, 22, 12, 22);
			g.endFill();
		}
		else
		{
			Art.line(g, 3, 0xFFFFFF);
			Art.poly(g, [26, 40, 46, 40], false);
		}
		if (variant == 2)
		{
			Art.line(g, 2.5, 0xFFFFFF);
			Art.poly(g, [36, 80, 36, 92], false);
		}
	}

	override function setup():Void
	{
		rows = level + 2;
		var n = cols * rows;
		var spyIndex = FlxG.random.int(0, n - 1);
		var variant = level == 0 ? 0 : level;
		var tint = G.CYAN;
		for (i in 0...n)
		{
			var isSpy = i == spyIndex;
			var key = isSpy ? "spy_v" + variant : "spy_v0";
			var v = isSpy ? variant : 0;
			var s = Art.sprite(key, 72, 92, function(g)
			{
				g.lineStyle();
				hull(g, v);
			}, 1, 7);
			s.color = isSpy && level == 0 ? G.RED : tint;
			if (isSpy)
				spy = s;
			ships.push(s);
			add(s);
		}
		place();
	}

	function place():Void
	{
		var gapX = 160.0;
		var gapY = Math.min(170, 600 / rows);
		var drift = level == 2 ? Math.sin(t * 1.6 * speed) * 30 : 0;
		for (i in 0...ships.length)
		{
			var s = ships[i];
			var c = i % cols;
			var r = Std.int(i / cols);
			var x = G.W / 2 + (c - 1) * gapX + drift * (r % 2 == 0 ? 1 : -1);
			var y = 500 + (r - (rows - 1) / 2) * gapY + Math.sin(t * 3 + i * 1.7) * 8;
			Art.center(s, x, y);
			s.angle = Math.sin(t * 2 + i) * 5;
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		place();
		if (tapped())
		{
			var hit:FlxSprite = null;
			for (s in ships)
				if (near(s, 62))
					hit = s;
			if (hit == null)
				return;
			if (hit == spy)
			{
				spy.color = G.RED;
				Audio.sfx("locked");
				boom(Art.cx(spy), Art.cy(spy), G.RED, false);
				cheer(Art.cx(spy), Art.cy(spy));
				win();
			}
			else
			{
				Audio.sfx("denied");
				hit.color = 0xFF6A6A7A;
				fx.burst(Art.cx(hit), Art.cy(hit), G.RED, 12, 200, 0.4, 0.5);
				spy.color = G.RED;
				fx.shock(Art.cx(spy), Art.cy(spy), G.RED, 0.9);
				lose();
			}
		}
	}
}
