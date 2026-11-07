package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Boss stage: three-lane hyperspace run. Switch lanes to dodge energy walls until you reach the gate. */
class Hyperlane extends Micro
{
	static var LANES:Array<Float> = [150, 270, 390];
	static inline var SHIPY:Float = 790;

	var ship:FlxSprite;
	var lane:Int = 1;
	var sx:Float = 270;
	var shipY:Float = SHIPY;
	var walls:Array<FlxSprite> = [];
	var wallLane:Array<Int> = [];
	var dashes:Array<FlxSprite> = [];
	var gate:FlxSprite;
	var v:Float;
	var interval:Float;
	var nextRow:Float;
	var t:Float = 0;
	var lastOpen:Int = 1;
	var progress:FlxSprite;
	var progressShip:FlxSprite;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 22);
		survive = true;
		outro = 1.0;
	}

	override function setup():Void
	{
		v = (720 + level * 90) * speed;
		interval = beat * [2.0, 1.6, 1.3][level];
		nextRow = beat * 1.5;

		for (x in [LANES[0] - 60, LANES[1] - 60, LANES[1] + 60, LANES[2] + 60])
		{
			var edge = x == LANES[0] - 60 || x == LANES[2] + 60;
			var r = Art.beam(edge ? 5 : 2);
			r.color = edge ? G.VIOLET : 0xFF2A3A80;
			Art.setBeam(r, x, 90, x, G.H);
			add(r);
		}
		for (i in 0...18)
		{
			var d = Art.beam(3);
			d.color = G.CYAN;
			d.alpha = 0.5;
			dashes.push(d);
			add(d);
		}

		gate = Art.sprite("bossgate", 420, 120, function(g)
		{
			Art.line(g, 8, G.GREEN);
			Art.poly(g, [10, 120, 10, 30, 40, 0, 380, 0, 410, 30, 410, 120], false);
			Art.line(g, 3, 0xFFFFFF);
			Art.poly(g, [40, 20, 380, 20], false);
		}, 1, 12);
		gate.visible = false;
		add(gate);

		ship = heroShip();
		progress = Art.panel(16, 520, 0x050818, 0x3A4A80, 0.8, 4, 2);
		progress.setPosition(G.W - 30, 200);
		add(progress);
		progressShip = Art.sprite("progdot", 20, 20, function(g)
		{
			Art.fill(g, G.CYAN);
			Art.poly(g, [10, 0, 20, 20, 0, 20]);
			g.endFill();
		}, 1, 5);
		add(progressShip);
		place(0);
	}

	function wall():FlxSprite
	{
		return Art.sprite("bosswall", 112, 44, function(g)
		{
			Art.fill(g, 0x3A0A18, 0.9);
			Art.line(g, 3, G.RED);
			Art.chamfer(g, 0, 0, 112, 44, 10);
			g.endFill();
			g.lineStyle();
			Art.fill(g, G.YELLOW, 0.8);
			for (i in 0...5)
				Art.poly(g, [10 + i * 20, 36, 22 + i * 20, 8, 30 + i * 20, 8, 18 + i * 20, 36]);
			g.endFill();
		}, 1, 10);
	}

	function spawnRow():Void
	{
		var open = FlxG.random.int(0, 2);
		if (Math.abs(open - lastOpen) > 1 && level == 0)
			open = 1;
		lastOpen = open;
		var blockBoth = level > 0 && FlxG.random.bool(level == 2 ? 70 : 45);
		for (i in 0...3)
		{
			if (i == open)
				continue;
			if (!blockBoth && i != (open + 1) % 3)
				continue;
			var w = wall();
			Art.center(w, LANES[i], -40);
			walls.push(w);
			wallLane.push(i);
			add(w);
		}
	}

	function place(elapsed:Float):Void
	{
		sx += (LANES[lane] - sx) * Math.min(1, elapsed * 20);
		Art.center(ship, sx, shipY);
		ship.angle = (LANES[lane] - sx) * 0.25;
		flameTo(ship, 1.6);
		for (i in 0...dashes.length)
		{
			var d = dashes[i];
			var col = i % 2 == 0 ? LANES[1] - 60 : LANES[1] + 60;
			var y = ((t * v + Std.int(i / 2) * 120) % 1080) - 100;
			Art.setBeam(d, col, y, col, y + 50);
		}
		var p = 1 - timeLeft / duration;
		progressShip.x = progress.x + progress.width / 2 - progressShip.width / 2;
		progressShip.y = progress.y + progress.height - 20 - p * (progress.height - 30);
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		var dir = 0;
		if (tapped() && !FlxG.keys.justPressed.SPACE)
			dir = px < sx ? -1 : 1;
		var sw = swiped();
		if (sw == 1)
			dir = 1;
		if (sw == 3)
			dir = -1;
		if (dir != 0)
		{
			var nl = Std.int(Math.max(0, Math.min(2, lane + dir)));
			if (nl != lane)
			{
				lane = nl;
				Audio.sfx("swipe");
				fx.burst(sx, SHIPY, G.CYAN, 6, 160, 0.25, 0.4);
			}
		}

		if (live())
		{
			nextRow -= elapsed;
			if (nextRow <= 0 && timeLeft > beat * 3.5)
			{
				nextRow += interval;
				spawnRow();
			}
		}
		if (timeLeft < beat * 2.5 && !gate.visible && !finished)
		{
			gate.visible = true;
			Art.center(gate, G.W / 2, -80);
		}
		if (gate.visible)
		{
			gate.y += v * 0.5 * elapsed;
			gate.alpha = 0.6 + Math.random() * 0.4;
		}

		for (i in 0...walls.length)
		{
			var w = walls[i];
			if (!w.alive)
				continue;
			w.y += v * elapsed;
			w.alpha = 0.8 + Math.random() * 0.2;
			if (live() && wallLane[i] == lane && Math.abs(Art.cy(w) - SHIPY) < 50 && Math.abs(Art.cx(w) - sx) < 70)
			{
				boom(sx, SHIPY);
				ship.visible = false;
				lose();
			}
			if (w.y > G.H + 50)
				w.kill();
		}
		if (finished && won)
		{
			shipY -= 1200 * elapsed;
		}
		if (FlxG.random.bool(60) && ship.visible)
			fx.puff(sx + FlxG.random.float(-6, 6), SHIPY + 60, G.ORANGE, 0, 600, 0.5, 0.25);
		place(elapsed);
	}

	override function win():Void
	{
		super.win();
		cheer(G.W / 2, 400, G.GREEN);
		Audio.sfx("warp");
		host.stars.flash = 0.7;
	}
}
