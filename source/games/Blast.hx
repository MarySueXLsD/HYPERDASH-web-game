package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Tap every drone before the fuse burns out. */
class Blast extends Micro
{
	var ship:FlxSprite;
	var drones:Array<FlxSprite> = [];
	var phase:Array<Float> = [];
	var beams:Array<FlxSprite> = [];
	var t:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 8);
	}

	override function setup():Void
	{
		ship = heroShip();
		Art.center(ship, G.W / 2, 820);
		flameTo(ship);
		var count = [3, 4, 6][level];
		for (i in 0...count)
		{
			var d = Art.drone();
			var x = 90 + (i % 3) * 180 + FlxG.random.float(-30, 30);
			var y = 220 + Std.int(i / 3) * 170 + FlxG.random.float(-30, 60);
			Art.center(d, x, y);
			d.ID = i;
			drones.push(d);
			phase.push(FlxG.random.float(0, 6.28));
			add(d);
		}
		place(0);
	}

	function place(dt:Float):Void
	{
		var amp = [30, 70, 110][level];
		for (i in 0...drones.length)
		{
			var d = drones[i];
			if (!d.alive)
				continue;
			var p = phase[i] + t * (1.6 + level * 0.6) * speed;
			var bx = 90 + (i % 3) * 180;
			var by = 230 + Std.int(i / 3) * 180;
			Art.center(d, bx + Math.sin(p) * amp, by + Math.cos(p * 1.3) * 26);
			d.angle = Math.sin(p) * 12;
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		place(elapsed);
		var aim = Math.atan2(py - Art.cy(ship), px - Art.cx(ship)) * 180 / Math.PI + 90;
		if (live())
			ship.angle += (Math.max(-40, Math.min(40, aim)) - ship.angle) * Math.min(1, elapsed * 14);
		flameTo(ship);

		for (b in beams)
			if (b.alive)
			{
				b.alpha -= elapsed * 6;
				if (b.alpha <= 0)
					b.kill();
			}

		if (tapped())
		{
			var hit:FlxSprite = null;
			for (d in drones)
				if (d.alive && near(d, 58))
					hit = d;
			var tx = hit != null ? Art.cx(hit) : px;
			var ty = hit != null ? Art.cy(hit) : py;
			var b = Art.beam(5);
			b.color = hit != null ? G.CYAN : 0xFF6A8AB0;
			Art.setBeam(b, Art.cx(ship), ship.y + 20, tx, ty);
			beams.push(b);
			add(b);
			Audio.sfx("laser", FlxG.random.float(0.9, 1.1));
			if (hit != null)
			{
				hit.kill();
				boom(tx, ty, G.RED, false);
				var left = 0;
				for (d in drones)
					if (d.alive)
						left++;
				if (left == 0)
				{
					cheer(tx, ty);
					win();
				}
			}
			else
				fx.burst(tx, ty, 0xFF6A8AB0, 6, 120, 0.25, 0.4);
		}
	}
}
