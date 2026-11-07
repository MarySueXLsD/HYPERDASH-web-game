package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Junk gets lobbed across the hold. Slash through it, but never through a parcel. */
class Slice extends Micro
{
	static inline var GRAVITY:Float = 1400;

	var items:Array<{s:FlxSprite, vx:Float, vy:Float, junk:Bool}> = [];
	var trail:Array<FlxSprite> = [];
	var trailI:Int = 0;
	var quota:Int;
	var cut:Int = 0;
	var airborne:Int = 0;
	var spawn:Float = 0;
	var gap:Float;
	var spawned:Int = 0;
	var parcelChance:Float;
	var lastX:Float = 0;
	var lastY:Float = 0;
	var tracking:Bool = false;
	var pips:Array<FlxSprite> = [];

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [8, 10, 12][level]);
	}

	override function setup():Void
	{
		quota = [3, 4, 6][level];
		gap = [1.4, 1.1, 0.8][level] * beat;
		parcelChance = [20, 30, 40][level];
		for (i in 0...10)
		{
			var b = Art.beam(6);
			b.color = G.CYAN;
			b.alpha = 0;
			trail.push(b);
			add(b);
		}
		for (i in 0...quota)
		{
			var pip = Art.sprite("slicepip", 26, 26, function(g)
			{
				Art.fill(g, 0xFFFFFF);
				Art.line(g, 3, G.INK);
				g.drawCircle(13, 13, 10);
				g.endFill();
			}, 0);
			pip.color = 0xFF5A5468;
			Art.center(pip, G.W / 2 + (i - (quota - 1) / 2) * 36, 110);
			pips.push(pip);
			add(pip);
		}
	}

	function launch(junk:Bool):Void
	{
		var s = junk ? Art.rock(FlxG.random.int(0, 7), 42) : Art.parcel();
		var x = FlxG.random.float(70, G.W - 70);
		Art.center(s, x, G.H + 60);
		s.angularVelocity = FlxG.random.float(-220, 220);
		add(s);
		var apex = FlxG.random.float(170, 400);
		var vy = -Math.sqrt(2 * GRAVITY * (G.H + 60 - apex));
		var vx = (G.W / 2 - x) * 0.35 + FlxG.random.float(-50, 50);
		items.push({s: s, vx: vx, vy: vy, junk: junk});
		spawned++;
		if (junk)
			airborne++;
	}

	static function hitsSegment(x:Float, y:Float, x1:Float, y1:Float, x2:Float, y2:Float, r:Float):Bool
	{
		var dx = x2 - x1;
		var dy = y2 - y1;
		var len = dx * dx + dy * dy;
		var k = len <= 0 ? 0.0 : Math.max(0, Math.min(1, ((x - x1) * dx + (y - y1) * dy) / len));
		var cx = x1 + dx * k;
		var cy = y1 + dy * k;
		return (x - cx) * (x - cx) + (y - cy) * (y - cy) < r * r;
	}

	override function tick(elapsed:Float):Void
	{
		var dt = elapsed * speed;
		if (live())
		{
			spawn -= elapsed;
			if (spawn <= 0)
			{
				spawn = gap;
				if (spawned > 0 && FlxG.random.bool(parcelChance))
					launch(false);
				else if (airborne + cut < quota)
					launch(true);
			}
		}

		var mx = px;
		var my = py;
		var slashing = false;
		if (live() && FlxG.mouse.pressed)
		{
			if (tracking && Micro.dist(lastX, lastY, mx, my) > 5)
			{
				slashing = true;
				var b = trail[trailI];
				trailI = (trailI + 1) % trail.length;
				b.alpha = 1;
				Art.setBeam(b, lastX, lastY, mx, my);
			}
			tracking = true;
		}
		else
			tracking = false;

		for (it in items)
		{
			if (!it.s.exists)
				continue;
			it.vy += GRAVITY * dt;
			it.s.x += it.vx * dt;
			it.s.y += it.vy * dt;
			if (it.s.y > G.H + 90 && it.vy > 0)
			{
				it.s.kill();
				if (it.junk)
					airborne--;
				continue;
			}
			if (slashing && hitsSegment(Art.cx(it.s), Art.cy(it.s), lastX, lastY, mx, my, 50))
			{
				if (it.junk)
				{
					boom(Art.cx(it.s), Art.cy(it.s), G.ORANGE, false);
					it.s.kill();
					airborne--;
					pips[cut].color = G.GREEN;
					cut++;
					if (cut >= quota)
					{
						cheer(mx, my);
						win();
						break;
					}
				}
				else
				{
					boom(Art.cx(it.s), Art.cy(it.s));
					it.s.kill();
					lose();
					break;
				}
			}
		}
		if (tracking)
		{
			lastX = mx;
			lastY = my;
		}
		for (b in trail)
			b.alpha = Math.max(0, b.alpha - elapsed * 7);
	}
}
