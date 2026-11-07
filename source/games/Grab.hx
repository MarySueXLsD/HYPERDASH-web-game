package games;

import core.Art;
import core.Juice;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Steer the ship around and scoop up every energy cell. */
class Grab extends Micro
{
	var ship:FlxSprite;
	var cells:Array<FlxSprite> = [];
	var vel:Array<{x:Float, y:Float}> = [];
	var sx:Float = G.W / 2;
	var sy:Float = 760;
	var t:Float = 0;
	var got:Int = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 8);
	}

	override function setup():Void
	{
		var count = [3, 4, 5][level];
		var spots = [];
		for (i in 0...count)
		{
			var x = 0.0;
			var y = 0.0;
			var ok = false;
			var tries = 0;
			while (!ok && tries < 40)
			{
				x = FlxG.random.float(70, G.W - 70);
				y = FlxG.random.float(170, 620);
				ok = true;
				for (s in spots)
					if (Micro.dist(x, y, s[0], s[1]) < 140)
						ok = false;
				tries++;
			}
			spots.push([x, y]);
			var c = Art.cell();
			Art.center(c, x, y);
			cells.push(c);
			add(c);
			var a = FlxG.random.float(0, Math.PI * 2);
			var v = level == 2 ? 110 * speed : (level == 1 ? 50 * speed : 0);
			vel.push({x: Math.cos(a) * v, y: Math.sin(a) * v});
		}
		ship = heroShip();
		Art.center(ship, sx, sy);
		flameTo(ship);
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		var ox = sx;
		var oy = sy;
		if (live() && (FlxG.mouse.pressed || FlxG.mouse.justMoved))
		{
			var k = Math.min(1, elapsed * 10);
			sx += (Math.max(40, Math.min(G.W - 40, px)) - sx) * k;
			sy += (Math.max(140, Math.min(880, py)) - sy) * k;
		}
		Art.center(ship, sx, sy);
		var dx = sx - ox;
		var dy = sy - oy;
		if (dx * dx + dy * dy > 1)
		{
			var a = Math.atan2(dy, dx) * 180 / Math.PI + 90;
			var diff = ((a - ship.angle + 540) % 360) - 180;
			ship.angle += diff * Math.min(1, elapsed * 10);
			fx.puff(sx - dx, sy - dy, G.ORANGE, -dx * 4, -dy * 4, 0.5, 0.3);
		}
		flameTo(ship, 0.6 + Math.min(1.5, Math.sqrt(dx * dx + dy * dy) / 8));

		for (i in 0...cells.length)
		{
			var c = cells[i];
			if (!c.alive)
				continue;
			var v = vel[i];
			c.x += v.x * elapsed;
			c.y += v.y * elapsed;
			if (Art.cx(c) < 50 || Art.cx(c) > G.W - 50)
				v.x = -v.x;
			if (Art.cy(c) < 160 || Art.cy(c) > 700)
				v.y = -v.y;
			c.angle = Math.sin(t * 3 + i) * 12;
			var s = 1 + Math.sin(t * 6 + i) * 0.06;
			c.scale.set(s, s);
			if (live() && Micro.dist(Art.cx(c), Art.cy(c), sx, sy) < 60)
			{
				c.kill();
				got++;
				Audio.sfx("coin", 1 + got * 0.08);
				Juice.small(Art.cx(c), Art.cy(c), G.GREEN);
				fx.burst(Art.cx(c), Art.cy(c), G.GREEN, 18, 300, 0.45, 0.6);
				fx.shock(Art.cx(c), Art.cy(c), G.GREEN, 0.6);
				if (got >= cells.length)
				{
					cheer(sx, sy);
					win();
				}
			}
		}
	}
}
