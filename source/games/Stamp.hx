package games;

import core.Art;
import core.Audio;
import core.G;
import core.Juice;
import core.Ui;
import flixel.FlxG;
import flixel.FlxSprite;

/** Parcels ride a belt under the stamp. Stamp every clean one, leave the bombs alone. */
class Stamp extends Micro
{
	static inline var ZONE:Float = 100;
	static inline var BELT:Float = 590;
	static inline var GAP:Float = 200;
	static inline var CX:Float = 270;

	var items:Array<{s:FlxSprite, clean:Bool, done:Bool, mark:FlxSprite}> = [];
	var ticks:Array<FlxSprite> = [];
	var head:FlxSprite;
	var v:Float;
	var t:Float = 0;
	var press:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [9, 10, 12][level]);
	}

	override function setup():Void
	{
		var n = [4, 5, 7][level];
		var startX = G.W + 70.0;
		var travel = startX + (n - 1) * GAP - (CX - ZONE);
		v = travel / (duration * 0.92);

		var belt = new FlxSprite().makeGraphic(G.W, 28, 0xFF2B2440);
		belt.y = BELT;
		add(belt);
		for (i in 0...14)
		{
			var b = Art.beam(4);
			b.color = 0xFF5A5468;
			ticks.push(b);
			add(b);
		}
		for (x in [CX - ZONE, CX + ZONE])
		{
			var l = Art.beam(4);
			l.color = G.YELLOW;
			Art.setBeam(l, x, BELT - 150, x, BELT + 28);
			add(l);
		}

		var bombs = 0;
		for (i in 0...n)
		{
			// The first parcel is always clean, so doing nothing can never pass.
			var clean = i == 0 || FlxG.random.bool(66);
			if (i == n - 1 && bombs == 0)
				clean = false;
			if (!clean)
				bombs++;
			var s = clean ? Art.parcel() : bomb();
			s.scale.set(1.4, 1.4);
			Art.center(s, startX + i * GAP, BELT - 50);
			add(s);
			items.push({s: s, clean: clean, done: false, mark: null});
		}

		head = Art.sprite("stamphead", 170, 200, function(g)
		{
			Art.fill(g, G.KRAFT);
			Art.line(g, 3, G.INK);
			g.drawRect(60, 2, 50, 120);
			g.endFill();
			Art.fill(g, G.ORANGE);
			Art.chamfer(g, 4, 118, 162, 78, 10);
			g.endFill();
		}, 0);
		add(head);
		placeHead();
	}

	function bomb():FlxSprite
	{
		return Art.sprite("stampbomb", 80, 70, function(g)
		{
			Art.fill(g, 0x3A0A14);
			Art.line(g, 3, G.RED);
			g.drawRect(2, 8, 76, 60);
			g.endFill();
			Art.line(g, 7, G.YELLOW);
			Art.poly(g, [22, 20, 58, 56], false);
			Art.poly(g, [58, 20, 22, 56], false);
		}, 1, 8);
	}

	function placeHead():Void
	{
		var drop = press * press * 130;
		head.x = CX - head.width / 2;
		head.y = 200 + drop;
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		press = Math.max(0, press - elapsed * 6);
		placeHead();
		for (i in 0...ticks.length)
		{
			var x = G.W + 40 - ((t * v + i * 48) % 672);
			Art.setBeam(ticks[i], x, BELT + 14, x + 18, BELT + 14);
		}

		if (tapped())
		{
			press = 1;
			var hit = null;
			for (it in items)
				if (!it.done && Math.abs(Art.cx(it.s) - CX) < ZONE)
				{
					hit = it;
					break;
				}
			if (hit == null)
				Audio.sfx("denied");
			else if (hit.clean)
			{
				hit.done = true;
				hit.mark = Ui.stamp("OK", 24, G.STAMP_GREEN, Art.cx(hit.s), Art.cy(hit.s), true, -8);
				add(hit.mark);
				Audio.sfx("slam");
				Juice.small(Art.cx(hit.s), Art.cy(hit.s), G.GREEN);
			}
			else
			{
				boom(Art.cx(hit.s), Art.cy(hit.s));
				hit.s.visible = false;
				lose();
			}
		}

		var allDone = true;
		for (it in items)
		{
			it.s.x -= v * elapsed;
			if (it.mark != null)
				it.mark.x -= v * elapsed;
			if (!it.done && live() && Art.cx(it.s) < CX - ZONE)
			{
				it.done = true;
				if (it.clean)
				{
					Audio.sfx("denied");
					it.s.color = 0xFFFF8080;
					fx.burst(Art.cx(it.s), Art.cy(it.s), G.RED, 14, 240, 0.4, 0.6);
					lose();
				}
				else
				{
					Audio.sfx("coin", 0.8);
					fx.burst(Art.cx(it.s), Art.cy(it.s), G.GREEN, 8, 160, 0.3, 0.4);
				}
			}
			if (!it.done)
				allDone = false;
		}
		if (allDone && live())
		{
			cheer(CX, BELT - 50);
			win();
		}
	}
}
