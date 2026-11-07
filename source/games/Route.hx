package games;

import core.Art;
import core.Audio;
import core.G;
import core.Juice;
import core.Ui;
import flixel.FlxG;
import flixel.FlxSprite;

/** A parcel slides down a sorting tree. Flip the switches so it lands in the lit bay. */
class Route extends Micro
{
	static inline var TOP:Float = 180;
	static inline var BOTTOM:Float = 730;

	var depth:Int;
	var nodeX:Array<Float> = [];
	var nodeY:Array<Float> = [];
	var dir:Array<Int> = [];
	var knobs:Array<FlxSprite> = [];
	var edges:Array<FlxSprite> = [];
	var bays:Array<FlxSprite> = [];
	var parcel:FlxSprite;
	var at:Int = 0;
	var e:Float = 0;
	var wait:Float;
	var segT:Float;
	var targetBay:Int;
	var t:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [9, 10, 8][level]);
	}

	override function setup():Void
	{
		depth = level == 0 ? 2 : 3;
		var total = (1 << (depth + 1)) - 1;
		var internal = (1 << depth) - 1;
		for (i in 0...total)
		{
			var d = Std.int(Math.log(i + 1) / Math.log(2) + 1e-9);
			var inRow = i - ((1 << d) - 1);
			nodeX.push(20 + (inRow + 0.5) * 500 / (1 << d));
			nodeY.push(TOP + d * (BOTTOM - TOP) / depth);
		}
		for (i in 0...internal)
		{
			dir.push(FlxG.random.int(0, 1));
			for (c in 0...2)
			{
				var b = Art.beam(6);
				edges.push(b);
				add(b);
			}
		}
		for (i in internal...total)
		{
			var bay = Art.sprite("routebay", 54, 46, function(g)
			{
				Art.fill(g, 0xFFFFFF);
				Art.line(g, 3, G.INK);
				Art.chamfer(g, 2, 2, 50, 42, 8);
				g.endFill();
			}, 0);
			bay.color = 0xFF5A5468;
			Art.center(bay, nodeX[i], nodeY[i] + 12);
			bays.push(bay);
			add(bay);
		}
		for (i in 0...internal)
		{
			var k = Art.sprite("routeknob", 66, 66, function(g)
			{
				Art.fill(g, G.KRAFT);
				Art.line(g, 3, G.INK);
				g.drawCircle(33, 33, 30);
				g.endFill();
				g.lineStyle();
				Art.fill(g, G.INK);
				Art.poly(g, [14, 26, 38, 26, 38, 14, 56, 33, 38, 52, 38, 40, 14, 40]);
				g.endFill();
			}, 0);
			Art.center(k, nodeX[i], nodeY[i]);
			knobs.push(k);
			add(k);
		}

		targetBay = FlxG.random.int(0, bays.length - 1);
		bays[targetBay].color = G.GREEN;
		var bx = nodeX[internal + targetBay];
		var by = nodeY[internal + targetBay];
		var mark = Ui.text(Math.max(0, Math.min(G.W - 120, bx - 60)), by + 44, 120, "Deliver", 16, G.GREEN);
		add(mark);
		// Start with the switches set wrong, so there is always something to do.
		if (followPath() == targetBay)
			dir[0] = 1 - dir[0];

		parcel = Art.parcel();
		parcel.scale.set(0.55, 0.55);
		add(parcel);
		wait = duration * 0.16;
		segT = duration * 0.72 / depth;
		paint();
	}

	/** The bay the parcel reaches if no switch changes from here. */
	function followPath():Int
	{
		var n = at;
		var internal = dir.length;
		while (n < internal)
			n = n * 2 + 1 + dir[n];
		return n - internal;
	}

	function paint():Void
	{
		var internal = dir.length;
		for (i in 0...internal)
		{
			for (c in 0...2)
			{
				var child = i * 2 + 1 + c;
				var b = edges[i * 2 + c];
				Art.setBeam(b, nodeX[i], nodeY[i], nodeX[child], nodeY[child]);
				b.color = dir[i] == c ? G.CYAN : 0xFF3A3358;
			}
			var chosen = i * 2 + 1 + dir[i];
			knobs[i].angle = Math.atan2(nodeY[chosen] - nodeY[i], nodeX[chosen] - nodeX[i]) * 180 / Math.PI;
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		var internal = dir.length;
		bays[targetBay].scale.x = bays[targetBay].scale.y = 1.05 + Math.sin(t * 8) * 0.08;
		if (tapped())
		{
			var best = -1;
			var bestD = 60.0;
			for (i in 0...internal)
			{
				var d = Micro.dist(px, py, nodeX[i], nodeY[i]);
				if (d < bestD)
				{
					bestD = d;
					best = i;
				}
			}
			if (best >= 0)
			{
				dir[best] = 1 - dir[best];
				Audio.sfx("flip", 1 + best * 0.05);
				Juice.small(nodeX[best], nodeY[best], G.CYAN);
				knobs[best].scale.set(1.2, 1.2);
				paint();
			}
		}
		for (k in knobs)
		{
			k.scale.x += (1 - k.scale.x) * Math.min(1, elapsed * 12);
			k.scale.y = k.scale.x;
		}

		if (live())
		{
			if (wait > 0)
				wait -= elapsed;
			else if (at < internal)
			{
				e += elapsed / segT;
				if (e >= 1)
				{
					e = 0;
					at = at * 2 + 1 + dir[at];
					Audio.sfx("tick");
				}
			}
			if (at >= internal)
			{
				var bay = at - internal;
				if (bay == targetBay)
				{
					Audio.sfx("dock");
					cheer(nodeX[at], nodeY[at]);
					win();
				}
				else
				{
					Audio.sfx("denied");
					boom(nodeX[at], nodeY[at], G.RED, false);
					lose();
				}
			}
		}

		var nx = nodeX[at];
		var ny = nodeY[at];
		if (at < internal)
		{
			var c = at * 2 + 1 + dir[at];
			nx += (nodeX[c] - nx) * e;
			ny += (nodeY[c] - ny) * e;
		}
		Art.center(parcel, nx, ny);
	}
}
