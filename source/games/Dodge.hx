package games;

import core.Art;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Drag the ship sideways to survive a rock shower. */
class Dodge extends Micro
{
	var ship:FlxSprite;
	var rocks:Array<FlxSprite> = [];
	var warns:Array<FlxSprite> = [];
	var plan:Array<{at:Float, x:Float, r:Float, vx:Float}> = [];
	var elapsedT:Float = 0;
	var shipX:Float = G.W / 2;
	var lastX:Float = G.W / 2;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 8);
		survive = true;
	}

	override function setup():Void
	{
		var count = [5, 8, 11][level];
		var span = duration * 0.72;
		for (i in 0...count)
		{
			var at = i / count * span + FlxG.random.float(0, 0.15) * beat;
			var x = i % 2 == 0 ? -1 : FlxG.random.float(60, G.W - 60);
			plan.push({at: at, x: x, r: FlxG.random.float(30, 46), vx: level == 2 && FlxG.random.bool(40) ? FlxG.random.float(-120, 120) : 0});
		}
		ship = heroShip();
		Art.center(ship, G.W / 2, 790);
		flameTo(ship);
	}

	override function tick(elapsed:Float):Void
	{
		elapsedT += elapsed;
		if (live())
		{
			var target = Math.max(50, Math.min(G.W - 50, px));
			lastX = shipX;
			shipX += (target - shipX) * Math.min(1, elapsed * 16);
		}
		Art.center(ship, shipX, 790);
		ship.angle = Math.max(-25, Math.min(25, (shipX - lastX) * 1.6));
		flameTo(ship, finished && !won ? 0 : 1);

		while (plan.length > 0 && plan[0].at <= elapsedT && live())
		{
			var p = plan.shift();
			var x = p.x < 0 ? Math.max(60, Math.min(G.W - 60, shipX + FlxG.random.float(-40, 40))) : p.x;
			var r = Art.rock(FlxG.random.int(0, 7), p.r);
			Art.center(r, x, -60);
			r.velocity.set(p.vx, (620 + level * 90) * speed);
			r.angularVelocity = FlxG.random.float(-200, 200);
			rocks.push(r);
			add(r);
			var w = Art.sprite("warn", 60, 14, function(g)
			{
				Art.fill(g, 0xFF3B5C);
				Art.poly(g, [0, 0, 60, 0, 30, 14]);
				g.endFill();
			}, 1, 6);
			Art.center(w, x, 100);
			w.ID = 0;
			warns.push(w);
			add(w);
		}

		for (w in warns)
		{
			w.ID++;
			w.alpha = w.ID % 8 < 4 ? 1 : 0.3;
			if (w.ID > 22)
				w.visible = false;
		}

		for (r in rocks)
		{
			if (!r.alive)
				continue;
			if (r.y > G.H + 80)
			{
				r.kill();
				continue;
			}
			var rr = r.width * 0.36;
			if (live() && Micro.dist(Art.cx(r), Art.cy(r), Art.cx(ship), Art.cy(ship) + 8) < rr + 26)
			{
				boom(Art.cx(ship), Art.cy(ship));
				ship.visible = false;
				r.kill();
				lose();
			}
		}
		if (FlxG.random.bool(30) && ship.visible)
			fx.puff(Art.cx(ship), ship.y + ship.height, G.ORANGE, 0, 300, 0.4, 0.3);
	}
}
