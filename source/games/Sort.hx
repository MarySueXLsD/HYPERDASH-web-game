package games;

import core.Art;
import core.Audio;
import core.G;
import core.Juice;
import flixel.FlxG;
import flixel.FlxSprite;
import openfl.display.Graphics;

/** Swipe each parcel left or right into the bay with the matching mark. */
class Sort extends Micro
{
	static inline var QY:Float = 560;
	static inline var GAP:Float = 92;

	static var TINTS:Array<Int> = [G.ORANGE, G.CYAN];

	var crates:Array<FlxSprite> = [];
	var kinds:Array<Int> = [];
	var bays:Array<Int> = [0, 1];
	var bayX:Array<Float> = [78, G.W - 78];
	var current:Int = 0;
	var flying:Array<{s:FlxSprite, x:Float}> = [];

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [8, 9, 10][level]);
	}

	static function mark(g:Graphics, kind:Int, x:Float, y:Float, color:Int):Void
	{
		if (kind == 0)
		{
			Art.line(g, 7, color);
			g.drawCircle(x, y, 18);
		}
		else
		{
			Art.line(g, 7, color);
			Art.poly(g, [x - 16, y - 16, x + 16, y + 16], false);
			Art.poly(g, [x + 16, y - 16, x - 16, y + 16], false);
		}
		g.lineStyle();
	}

	override function setup():Void
	{
		if (level > 0 && FlxG.random.bool(50))
			bays = [1, 0];
		for (side in 0...2)
		{
			var kind = bays[side];
			var b = Art.sprite("sortbay" + kind, 120, 240, function(g)
			{
				Art.fill(g, 0xFFFFFF, 0.14);
				Art.line(g, 5, 0xFFFFFF);
				Art.chamfer(g, 3, 3, 114, 234, 14);
				g.endFill();
				mark(g, kind, 60, 120, 0xFFFFFF);
			}, 1, 8);
			b.color = TINTS[kind];
			Art.center(b, bayX[side], QY);
			add(b);
		}

		var n = [3, 4, 6][level];
		var last = -1;
		var runLength = 0;
		for (i in 0...n)
		{
			var k = FlxG.random.int(0, 1);
			// No more than two of a kind in a row, so the swipe has to keep changing.
			if (k == last && runLength >= 2)
				k = 1 - k;
			runLength = k == last ? runLength + 1 : 1;
			last = k;
			kinds.push(k);
		}
		// Added back to front so the next parcel always sits on top of the queue.
		var i = n - 1;
		var made:Array<FlxSprite> = [];
		while (i >= 0)
		{
			var k = kinds[i];
			var c = Art.sprite("sortcrate" + k, 124, 104, function(g)
			{
				Art.fill(g, 0xFFFFFF);
				Art.line(g, 3, G.INK);
				g.drawRect(2, 2, 120, 100);
				g.endFill();
				mark(g, k, 62, 52, G.INK);
			}, 0);
			c.color = TINTS[k];
			Art.center(c, G.W / 2, QY - i * GAP);
			made.push(c);
			add(c);
			i--;
		}
		made.reverse();
		crates = made;
		place(1);
	}

	function place(blend:Float):Void
	{
		for (i in current...crates.length)
		{
			var c = crates[i];
			var slot = i - current;
			var ty = QY - slot * GAP - c.height / 2;
			c.y += (ty - c.y) * blend;
			var s = slot == 0 ? 1.0 : 0.72;
			c.scale.set(s, s);
			c.alpha = slot < 4 ? 1 : 0;
		}
	}

	override function tick(elapsed:Float):Void
	{
		var sw = swiped();
		if ((sw == 1 || sw == 3) && current < crates.length)
		{
			var side = sw == 3 ? 0 : 1;
			var c = crates[current];
			flying.push({s: c, x: bayX[side]});
			if (bays[side] == kinds[current])
			{
				Audio.sfx("swipe");
				Juice.small(bayX[side], QY, TINTS[kinds[current]]);
				current++;
				if (current >= crates.length)
				{
					cheer(bayX[side], QY);
					win();
				}
			}
			else
			{
				Audio.sfx("denied");
				boom(bayX[side], QY, G.RED, false);
				current = crates.length;
				lose();
			}
		}
		for (f in flying)
		{
			f.s.x += (f.x - Art.cx(f.s)) * Math.min(1, elapsed * 16);
			f.s.scale.x = f.s.scale.y = Math.max(0.2, f.s.scale.x - elapsed * 3);
			f.s.alpha = Math.max(0, f.s.alpha - elapsed * 4);
		}
		place(Math.min(1, elapsed * 18));
	}
}
