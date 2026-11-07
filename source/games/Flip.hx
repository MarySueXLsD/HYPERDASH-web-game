package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/**
 * Tunnel run seen from far away: tap to swap between floor and ceiling and dodge
 * the spikes. The whole scene is drawn at ZOOM, so the same tunnel moves slower
 * on screen and spikes are visible for much longer before they arrive.
 */
class Flip extends Micro
{
	static inline var ZOOM:Float = 0.6;
	static inline var MID:Float = 480;
	static inline var FLOOR:Float = MID + 180 * ZOOM;
	static inline var CEIL:Float = MID - 180 * ZOOM;
	static inline var RAIL:Float = 60 * ZOOM;
	static inline var SHIPX:Float = 76;
	static inline var SPAWNX:Float = 590;

	var ship:FlxSprite;
	var spikes:Array<FlxSprite> = [];
	var lanes:Array<Int> = [];
	var rails:Array<FlxSprite> = [];
	var plan:Array<{at:Float, lane:Int}> = [];
	var up:Bool = false;
	var pos:Float = 0;
	var v:Float;
	var t:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 10);
		survive = true;
	}

	override function setup():Void
	{
		v = 760 * ZOOM * speed;
		var count = [3, 4, 5][level];
		var travel = (SPAWNX - SHIPX) / v;
		var first = Math.max(duration * 0.24, travel + 0.02);
		var last = duration * 0.94;
		var lane = 0;
		for (i in 0...count)
		{
			var arrive = first + (last - first) * (count == 1 ? 0 : i / (count - 1));
			if (i == 0)
				lane = 0;
			else
				lane = FlxG.random.bool(70) ? 1 - lane : lane;
			plan.push({at: arrive - travel, lane: lane});
		}

		// Station hull above and below the tunnel, so the far-away view has some scale.
		var top = CEIL - RAIL;
		var bottom = FLOOR + RAIL;
		for (y in [top - 150, bottom])
		{
			var hull = new FlxSprite().makeGraphic(G.W, 150, 0xFF1C1538);
			hull.y = y;
			add(hull);
		}
		for (y in [top, bottom])
		{
			var r = Art.beam(4);
			r.color = G.VIOLET;
			Art.setBeam(r, 0, y, G.W, y);
			add(r);
		}
		for (i in 0...24)
		{
			var r = Art.beam(2);
			r.color = 0xFF3A2A70;
			rails.push(r);
			add(r);
		}
		ship = heroShip();
		place(0);
	}

	function spike(lane:Int):FlxSprite
	{
		var s = Art.sprite("spike", 90, 100, function(g)
		{
			Art.fill(g, 0x2A0A18);
			Art.line(g, 3, G.RED);
			Art.poly(g, [0, 100, 20, 30, 34, 70, 45, 0, 56, 70, 70, 30, 90, 100]);
			g.endFill();
		}, 1, 8);
		s.flipY = lane == 1;
		s.scale.set(ZOOM, ZOOM);
		var reach = s.height * ZOOM / 2 - 8;
		Art.center(s, SPAWNX, lane == 0 ? FLOOR + RAIL - reach : CEIL - RAIL + reach);
		add(s);
		return s;
	}

	function place(elapsed:Float):Void
	{
		var target = up ? 1.0 : 0.0;
		pos += (target - pos) * Math.min(1, elapsed * 22);
		var y = FLOOR + (CEIL - FLOOR) * pos;
		Art.center(ship, SHIPX, y);
		ship.angle = 90;
		ship.flipX = pos > 0.5;
		ship.scale.set(ZOOM, ZOOM * (Math.abs(1 - pos * 2) * 0.4 + 0.6));
		flameTo(ship, 1.3, ZOOM);
		for (i in 0...rails.length)
		{
			var r = rails[i];
			var lower = i >= 12;
			var ry = lower ? FLOOR + RAIL - 8 : CEIL - RAIL + 8;
			var x = G.W + 40 - ((t * v + (i % 12) * 54) % 648);
			Art.setBeam(r, x, ry, x + 26, ry);
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		if (tapped())
		{
			up = !up;
			Audio.sfx("flip", up ? 1.2 : 0.9);
			fx.burst(SHIPX, Art.cy(ship), G.CYAN, 8, 200, 0.3, 0.5);
		}
		while (plan.length > 0 && plan[0].at <= t && !finished)
		{
			var p = plan.shift();
			spikes.push(spike(p.lane));
			lanes.push(p.lane);
		}
		for (i in 0...spikes.length)
		{
			var s = spikes[i];
			s.x -= v * elapsed;
			if (live() && Math.abs(Art.cx(s) - SHIPX) < 50 * ZOOM)
			{
				var shipLane = pos > 0.5 ? 1 : 0;
				if (shipLane == lanes[i])
				{
					boom(SHIPX, Art.cy(ship));
					ship.visible = false;
					lose();
				}
			}
		}
		if (FlxG.random.bool(50) && ship.visible)
			fx.puff(SHIPX - 34, Art.cy(ship), G.ORANGE, -200, 0, 0.35, 0.3);
		place(elapsed);
	}
}
