package games;

import core.Art;
import core.Juice;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Swipe in each arrow's direction to barrel-roll out of the laser's path. */
class Evade extends Micro
{
	static inline var SX:Float = 270;
	static inline var SY:Float = 600;

	var ship:FlxSprite;
	var arrows:Array<FlxSprite> = [];
	var dirs:Array<Int> = [];
	var current:Int = 0;
	var offX:Float = 0;
	var offY:Float = 0;
	var roll:Float = 0;
	var lasers:Array<FlxSprite> = [];
	var t:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [6, 8, 9][level]);
	}

	override function setup():Void
	{
		var n = level + 1;
		var last = -1;
		for (i in 0...n)
		{
			var d = FlxG.random.int(0, 3, [last]);
			last = d;
			dirs.push(d);
			var a = Art.sprite("evadearrow", 110, 110, function(g)
			{
				Art.fill(g, 0xFFFFFF, 0.15);
				Art.line(g, 8, 0xFFFFFF);
				Art.poly(g, [55, 8, 102, 60, 76, 60, 76, 102, 34, 102, 34, 60, 8, 60]);
				g.endFill();
			}, 1, 10);
			a.angle = d * 90;
			var x = SX + (i - (n - 1) / 2) * 150;
			Art.center(a, x, 250);
			arrows.push(a);
			add(a);
		}
		ship = heroShip();
		place();
	}

	function place():Void
	{
		Art.center(ship, SX + offX, SY + offY);
		ship.scale.x = Math.cos(roll);
		flameTo(ship, 1);
		for (i in 0...arrows.length)
		{
			var a = arrows[i];
			if (i < current)
				a.color = G.GREEN;
			else if (i == current)
			{
				a.color = G.YELLOW;
				var s = 1.05 + Math.sin(t * 14) * 0.08;
				a.scale.set(s, s);
			}
			else
			{
				a.color = 0xFF5A6A90;
				a.scale.set(0.85, 0.85);
			}
		}
	}

	function laser(dir:Int, hitShip:Bool):Void
	{
		var b = Art.beam(14);
		b.color = G.RED;
		if (dir == 0 || dir == 2)
			Art.setBeam(b, 0, SY, G.W, SY);
		else
			Art.setBeam(b, SX, 80, SX, G.H);
		lasers.push(b);
		add(b);
		Audio.sfx("laser", 0.6);
		Juice.shake(0.15);
		if (hitShip)
			boom(SX, SY, G.RED);
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		var sw = swiped();
		if (sw >= 0)
		{
			if (sw == dirs[current])
			{
				Audio.sfx("swipe");
				Juice.small(SX, SY, G.CYAN);
				var dist = 150.0;
				offX = sw == 1 ? dist : (sw == 3 ? -dist : 0);
				offY = sw == 0 ? -dist : (sw == 2 ? dist : 0);
				roll = Math.PI * 2;
				fx.burst(Art.cx(arrows[current]), Art.cy(arrows[current]), G.GREEN, 14, 260, 0.4, 0.6);
				laser(sw, false);
				current++;
				if (current >= dirs.length)
				{
					cheer(SX + offX, SY + offY);
					win();
				}
			}
			else
			{
				laser(dirs[current], true);
				ship.visible = false;
				lose();
			}
		}
		offX *= Math.pow(0.002, elapsed);
		offY *= Math.pow(0.002, elapsed);
		roll *= Math.pow(0.001, elapsed);
		if (Math.abs(offX) > 4 || Math.abs(offY) > 4)
			fx.puff(Art.cx(ship), Art.cy(ship), G.CYAN, 0, 0, 0.8, 0.25);
		for (l in lasers)
		{
			l.alpha -= elapsed * 3;
			l.scale.y = 1 + Math.random() * 0.5;
		}
		place();
	}
}
