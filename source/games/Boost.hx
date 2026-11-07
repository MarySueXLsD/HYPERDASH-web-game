package games;

import core.Art;
import core.Juice;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Mash to out-thrust the rival courier to the finish line. */
class Boost extends Micro
{
	static inline var START:Float = 800;
	static inline var FINISH:Float = 200;

	var ship:FlxSprite;
	var rival:FlxSprite;
	var rivalFlame:FlxSprite;
	var line:FlxSprite;
	var lanes:Array<FlxSprite> = [];
	var y:Float = START;
	var vy:Float = 0;
	var ry:Float = START;
	var rivalSpeed:Float;
	var push:Float;
	var t:Float = 0;
	var taps:Int = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 7);
	}

	override function setup():Void
	{
		var need = [10, 13, 16][level];
		push = (START - FINISH) / need;
		rivalSpeed = (START - FINISH) / (duration * 0.92);

		for (i in 0...10)
		{
			var l = Art.beam(2);
			l.color = 0xFF2A3A70;
			l.angle = 90;
			lanes.push(l);
			add(l);
		}
		line = Art.sprite("finish", 500, 24, function(g)
		{
			g.lineStyle();
			for (i in 0...25)
			{
				Art.fill(g, i % 2 == 0 ? 0xF2F7FF : 0x3CF0FF);
				g.drawRect(i * 20, (i % 2) * 12, 20, 12);
				Art.fill(g, i % 2 == 1 ? 0xF2F7FF : 0x3CF0FF, 0.3);
				g.drawRect(i * 20, 12 - (i % 2) * 12, 20, 12);
			}
			g.endFill();
		}, 1, 6);
		Art.center(line, G.W / 2, FINISH - 40);
		add(line);

		rivalFlame = Art.flame();
		add(rivalFlame);
		rival = Art.ship(G.RED, "ship_rival");
		add(rival);
		ship = heroShip();
		place();
	}

	function place():Void
	{
		Art.center(ship, G.W / 2 + 100, y);
		Art.center(rival, G.W / 2 - 100, ry);
		rivalFlame.x = Art.cx(rival) - rivalFlame.width / 2;
		rivalFlame.y = Art.cy(rival) + 40;
		var k = 0.9 + Math.random() * 0.3;
		rivalFlame.scale.set(k, k * 1.1);
		flameTo(ship, 0.8 + Math.min(2, vy / 500));
		for (i in 0...lanes.length)
		{
			var l = lanes[i];
			var x = i < 5 ? 40.0 : G.W - 40.0;
			var off = (t * 900 * speed + (i % 5) * 200) % 1000;
			l.scale.x = 1.2;
			l.x = x;
			l.y = off - 100;
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		if (tapped())
		{
			taps++;
			vy += push * 3.9;
			Audio.sfx("thrust", 1.5);
			Audio.sfx("charge", 1 + taps * 0.05);
			fx.burst(Art.cx(ship), ship.y + ship.height - 10, G.ORANGE, 6, 200, 0.3, 0.5);
			Juice.shake(0.06);
			ship.scale.set(0.86, 1.2);
		}
		ship.scale.x += (1 - ship.scale.x) * Math.min(1, elapsed * 12);
		ship.scale.y += (1 - ship.scale.y) * Math.min(1, elapsed * 12);

		if (!finished)
		{
			y -= vy * elapsed;
			vy *= Math.pow(0.02, elapsed);
			ry -= rivalSpeed * elapsed;
		}
		else if (won)
			y -= 900 * elapsed;
		else
			ry -= 900 * elapsed;

		if (live())
		{
			if (y <= FINISH)
			{
				cheer(Art.cx(ship), FINISH);
				Audio.sfx("coin");
				win();
			}
			else if (ry <= FINISH)
			{
				fx.burst(Art.cx(rival), FINISH, G.RED, 20, 300, 0.5, 0.6);
				lose();
			}
		}
		if (FlxG.random.bool(40))
			fx.puff(Art.cx(rival), rival.y + rival.height, G.RED, 0, 300, 0.4, 0.3);
		place();
	}
}
