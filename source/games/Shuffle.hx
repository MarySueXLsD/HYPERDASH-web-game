package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** A parcel hides under one pod, the pods shuffle, and you tap where it ended up. */
class Shuffle extends Micro
{
	static inline var RY:Float = 500;

	var pods:Array<FlxSprite> = [];
	var slot:Array<Int> = [];
	var parcel:FlxSprite;
	var hidden:Int;
	var swaps:Array<{a:Int, b:Int}> = [];
	var showFor:Float;
	var swapFor:Float;
	var spacing:Float;
	var t:Float = 0;
	var picked:Int = -1;
	var lastSwap:Int = -1;
	var lift:Array<Float> = [];

	public function new(level:Int, speed:Float)
	{
		// Tracking gets hard fast, so warp only half applies.
		super(level, 1 + (speed - 1) * 0.5, [10, 11, 12][level]);
	}

	override function setup():Void
	{
		var n = level == 2 ? 4 : 3;
		spacing = n == 4 ? 124 : 156;
		showFor = 1.8 * beat;
		swapFor = [1.0, 0.8, 0.7][level] * beat;
		var count = [3, 5, 7][level];
		hidden = FlxG.random.int(0, n - 1);

		parcel = Art.parcel();
		parcel.scale.set(0.9, 0.9);
		add(parcel);
		for (i in 0...n)
		{
			var pod = Art.sprite("shufflepod", 120, 130, function(g)
			{
				Art.fill(g, 0x2B2440);
				Art.line(g, 4, G.KRAFT);
				Art.poly(g, [8, 126, 8, 56, 24, 22, 60, 6, 96, 22, 112, 56, 112, 126]);
				g.endFill();
				g.lineStyle();
				Art.fill(g, G.ORANGE);
				g.drawRect(8, 90, 104, 14);
				g.endFill();
				Art.fill(g, G.CYAN);
				g.drawCircle(60, 50, 12);
				g.endFill();
			}, 0);
			pods.push(pod);
			slot.push(i);
			lift.push(i == hidden ? 1 : 0);
			add(pod);
		}
		var last = -1;
		for (i in 0...count)
		{
			var a = FlxG.random.int(0, n - 1);
			var b = FlxG.random.int(0, n - 1, [a]);
			// Don't repeat the same pair, or two swaps cancel out and look like nothing happened.
			if (a + b * 10 == last || b + a * 10 == last)
			{
				a = (a + 1) % n;
				b = FlxG.random.int(0, n - 1, [a]);
			}
			last = a + b * 10;
			swaps.push({a: a, b: b});
		}
		place();
	}

	inline function slotX(i:Float):Float
	{
		return G.W / 2 + (i - (pods.length - 1) / 2) * spacing;
	}

	/** Which swap is running right now, or -1 before they start and `swaps.length` after. */
	function currentSwap():Int
	{
		if (t < showFor)
			return -1;
		return Std.int(Math.min(swaps.length, (t - showFor) / swapFor));
	}

	function place():Void
	{
		var k = currentSwap();
		var e = k >= 0 && k < swaps.length ? (t - showFor) / swapFor - k : 0.0;
		var ease = e * e * (3 - 2 * e);
		for (i in 0...pods.length)
		{
			var x = slotX(slot[i]);
			var y = RY;
			if (k >= 0 && k < swaps.length)
			{
				var sw = swaps[k];
				if (i == sw.a)
				{
					x += (slotX(slot[sw.b]) - x) * ease;
					y -= Math.sin(e * Math.PI) * 90;
				}
				else if (i == sw.b)
				{
					x += (slotX(slot[sw.a]) - x) * ease;
					y += Math.sin(e * Math.PI) * 90;
				}
			}
			Art.center(pods[i], x, y - lift[i] * 130);
			if (i == hidden)
				Art.center(parcel, x, y + 26);
		}
		parcel.visible = lift[hidden] > 0.05;
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		var k = currentSwap();
		if (k != lastSwap)
		{
			if (lastSwap >= 0 && lastSwap < swaps.length)
			{
				var done = swaps[lastSwap];
				var tmp = slot[done.a];
				slot[done.a] = slot[done.b];
				slot[done.b] = tmp;
			}
			if (k >= 0 && k < swaps.length)
				Audio.sfx("swipe");
			lastSwap = k;
		}
		// Hold the lift while the parcel is being shown, or once the choice is made.
		for (i in 0...pods.length)
		{
			var want = (t < showFor * 0.75 && i == hidden) || (finished && (i == picked || i == hidden)) ? 1.0 : 0.0;
			lift[i] += (want - lift[i]) * Math.min(1, elapsed * 14);
		}
		if (k >= swaps.length && tapped())
		{
			var hit = -1;
			for (i in 0...pods.length)
				if (near(pods[i], 80))
					hit = i;
			if (hit >= 0)
			{
				picked = hit;
				if (hit == hidden)
				{
					Audio.sfx("locked");
					cheer(Art.cx(pods[hit]), RY);
					win();
				}
				else
				{
					Audio.sfx("denied");
					fx.burst(Art.cx(pods[hit]), RY, G.RED, 14, 240, 0.4, 0.6);
					lose();
				}
			}
		}
		place();
	}
}
