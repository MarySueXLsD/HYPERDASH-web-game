package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Orbit the planet and tap to release along the tangent, through the gate. */
class Slingshot extends Micro
{
	static inline var CX:Float = 270;
	static inline var CY:Float = 560;
	static inline var ORBIT:Float = 150;

	var planet:FlxSprite;
	var ship:FlxSprite;
	var gate:FlxSprite;
	var dots:Array<FlxSprite> = [];
	var ang:Float;
	var omega:Float;
	var gx:Float;
	var gy:Float;
	var gr:Float;
	var flying:Bool = false;
	var sx:Float;
	var sy:Float;
	var vx:Float = 0;
	var vy:Float = 0;
	var preview:Int;
	var passed:Bool = false;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 9);
	}

	override function setup():Void
	{
		omega = [2.0, 2.6, 3.2][level] * speed;
		gr = [62, 50, 40][level];
		preview = [14, 8, 4][level];
		var ga = FlxG.random.float(-Math.PI * 0.85, -Math.PI * 0.15);
		var gd = FlxG.random.float(300, 360);
		gx = CX + Math.cos(ga) * gd;
		gy = CY + Math.sin(ga) * gd;
		gx = Math.max(gr + 30, Math.min(G.W - gr - 30, gx));
		gy = Math.max(170, gy);
		ang = FlxG.random.float(0, Math.PI * 2);

		var orbit = Art.sprite("orbitpath", 310, 310, function(g)
		{
			Art.line(g, 2, 0x3A4A80);
			var n = 48;
			for (i in 0...n)
				if (i % 2 == 0)
				{
					var a1 = i / n * Math.PI * 2;
					var a2 = (i + 1) / n * Math.PI * 2;
					Art.poly(g, [155 + Math.cos(a1) * ORBIT, 155 + Math.sin(a1) * ORBIT, 155 + Math.cos(a2) * ORBIT, 155 + Math.sin(a2) * ORBIT], false);
				}
		}, 0);
		Art.center(orbit, CX, CY);
		add(orbit);
		planet = Art.sprite("slingplanet", 150, 150, function(g)
		{
			Art.radial(g, 75, 75, 75, 0xFF9A3C, 0xFF3C3C, 0.6, 0);
			Art.fill(g, 0x3A1A30);
			Art.line(g, 4, 0xFFB07A);
			g.drawCircle(75, 75, 56);
			g.endFill();
			Art.line(g, 3, 0xFF9A3C, 0.6);
			g.drawEllipse(30, 60, 90, 18);
		}, 1, 10);
		Art.center(planet, CX, CY);
		add(planet);
		gate = Art.sprite("gate" + gr, Std.int(gr * 2 + 20), Std.int(gr * 2 + 20), function(g)
		{
			var c = gr + 10;
			Art.line(g, 6, G.GREEN);
			g.drawCircle(c, c, gr);
			Art.line(g, 2, G.GREEN, 0.5);
			g.drawCircle(c, c, gr - 12);
		}, 1, 10);
		Art.center(gate, gx, gy);
		add(gate);

		for (i in 0...preview)
		{
			var d = new FlxSprite();
			d.loadGraphic(Art.dot());
			d.scale.set(0.35, 0.35);
			d.blend = openfl.display.BlendMode.ADD;
			dots.push(d);
			add(d);
		}
		ship = heroShip();
		place(0);
	}

	function place(elapsed:Float):Void
	{
		if (!flying)
		{
			ang += omega * elapsed;
			sx = CX + Math.cos(ang) * ORBIT;
			sy = CY + Math.sin(ang) * ORBIT;
			vx = -Math.sin(ang);
			vy = Math.cos(ang);
		}
		Art.center(ship, sx, sy);
		ship.angle = Math.atan2(vy, vx) * 180 / Math.PI + 90;
		flameTo(ship, flying ? 2 : 1);
		for (i in 0...dots.length)
		{
			var d = dots[i];
			var k = (i + 1) * 34;
			Art.center(d, sx + vx * k, sy + vy * k);
			d.visible = !flying;
			d.alpha = 1 - i / dots.length * 0.7;
			d.color = aimed() ? G.GREEN : G.WHITE;
		}
		gate.angle += elapsed * 40;
		var s = 1 + Math.sin(gate.angle * 0.1) * 0.04;
		gate.scale.set(s, s);
	}

	/** True when the current tangent passes through the gate. */
	function aimed():Bool
	{
		var dx = gx - sx;
		var dy = gy - sy;
		var along = dx * vx + dy * vy;
		if (along <= 0)
			return false;
		var perp = Math.abs(dx * vy - dy * vx);
		return perp < gr - 10;
	}

	override function tick(elapsed:Float):Void
	{
		if (tapped() && !flying)
		{
			flying = true;
			Audio.sfx("warp");
			host.kick(0.6);
		}
		if (flying)
		{
			var sp = 1100 * elapsed;
			sx += vx * sp;
			sy += vy * sp;
			fx.puff(sx, sy, G.ORANGE, -vx * 200, -vy * 200, 0.7, 0.4);
			if (live() && Micro.dist(sx, sy, gx, gy) < gr - 6)
			{
				passed = true;
				Audio.sfx("coin");
				cheer(gx, gy);
				win();
			}
			if (live() && (sx < -60 || sx > G.W + 60 || sy < -60 || sy > G.H + 60))
				lose();
			if (live() && Micro.dist(sx, sy, CX, CY) < 60)
			{
				boom(sx, sy);
				ship.visible = false;
				lose();
			}
		}
		place(elapsed);
	}
}
