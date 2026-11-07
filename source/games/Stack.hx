package games;

import core.Art;
import core.Audio;
import core.G;
import core.Juice;
import flixel.FlxG;
import flixel.FlxSprite;

/** A crate slides over the stack. Tap to drop it. Whatever overhangs gets sheared off. */
class Stack extends Micro
{
	static inline var FLOOR:Float = 800;
	static inline var CH:Float = 64;
	static inline var MAXW:Float = 240;

	var need:Int;
	var placed:Int = 0;
	var crate:FlxSprite;
	var width_:Float = MAXW;
	var topX:Float = G.W / 2;
	var topW:Float = MAXW;
	var x_:Float = 0;
	var y_:Float = 0;
	var dir:Float = 1;
	var v:Float;
	var dropping:Bool = false;
	var dropV:Float = 0;
	var scraps:Array<{s:FlxSprite, vx:Float, vy:Float}> = [];
	var tints:Array<Int> = [G.KRAFT, G.PAPER];

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [9, 10, 12][level]);
	}

	override function setup():Void
	{
		need = [3, 4, 5][level];
		v = [260, 320, 380][level] * speed;
		var base = Art.panel(Std.int(MAXW + 50), 26, G.INK, G.KRAFT, 1, 6, 3);
		Art.center(base, G.W / 2, FLOOR + 13);
		add(base);
		next();
	}

	function block(w:Float, tint:Int):FlxSprite
	{
		var s = Art.sprite("stackcrate", Std.int(MAXW), Std.int(CH), function(g)
		{
			Art.fill(g, 0xFFFFFF);
			Art.line(g, 3, G.INK);
			g.drawRect(2, 2, MAXW - 4, CH - 4);
			g.endFill();
			g.lineStyle();
			Art.fill(g, 0xB8935A);
			g.drawRect(MAXW / 2 - 12, 2, 24, CH - 4);
			g.endFill();
		}, 0);
		s.color = tint;
		s.scale.x = w / MAXW;
		add(s);
		return s;
	}

	inline function topY():Float
	{
		return FLOOR - placed * CH;
	}

	function next():Void
	{
		crate = block(topW, tints[placed % 2]);
		width_ = topW;
		dir = placed % 2 == 0 ? 1 : -1;
		x_ = dir > 0 ? width_ / 2 + 10 : G.W - width_ / 2 - 10;
		y_ = topY() - CH / 2 - 120;
		dropping = false;
		dropV = 0;
		Art.center(crate, x_, y_);
	}

	function shear(cx:Float, w:Float, side:Float):Void
	{
		if (w < 4)
			return;
		var s = block(w, crate.color);
		Art.center(s, cx, y_);
		s.angularVelocity = side * 200;
		scraps.push({s: s, vx: side * 180, vy: -120});
	}

	override function tick(elapsed:Float):Void
	{
		for (sc in scraps)
		{
			sc.vy += 1600 * elapsed;
			sc.s.x += sc.vx * elapsed;
			sc.s.y += sc.vy * elapsed;
		}
		if (crate == null || finished && !dropping)
			return;

		if (!dropping)
		{
			x_ += dir * v * elapsed;
			if (x_ > G.W - width_ / 2 - 10)
				dir = -1;
			if (x_ < width_ / 2 + 10)
				dir = 1;
			if (tapped())
			{
				dropping = true;
				Audio.sfx("flip", 0.8);
			}
		}
		else
		{
			dropV += 3200 * elapsed;
			y_ += dropV * elapsed;
			var rest = topY() - CH / 2;
			if (y_ >= rest)
			{
				y_ = rest;
				dropping = false;
				land();
			}
		}
		if (crate != null)
			Art.center(crate, x_, y_);
	}

	function land():Void
	{
		var off = x_ - topX;
		var overlap = (topW + width_) / 2 - Math.abs(off);
		if (overlap <= 14)
		{
			// Clean miss: the crate tumbles away.
			shear(x_, width_, off > 0 ? 1 : -1);
			crate.visible = false;
			crate = null;
			boom(x_, y_, G.RED, false);
			Audio.sfx("denied");
			lose();
			return;
		}
		if (Math.abs(off) < 10)
		{
			// Close enough counts as perfect, so a good tap never costs width.
			x_ = topX;
			Audio.sfx("locked");
			fx.burst(x_, y_ + CH / 2, G.YELLOW, 14, 260, 0.4, 0.5);
		}
		else
		{
			var side = off > 0 ? 1 : -1;
			var cutW = width_ - overlap;
			shear(x_ + side * (width_ / 2 - cutW / 2), cutW, side);
			x_ -= side * cutW / 2;
			width_ = overlap;
			crate.scale.x = width_ / MAXW;
			Audio.sfx("dock");
			Juice.small(x_, y_ + CH / 2, G.KRAFT);
		}
		Art.center(crate, x_, y_);
		topX = x_;
		topW = width_;
		placed++;
		if (placed >= need)
		{
			crate = null;
			cheer(topX, y_);
			win();
			return;
		}
		next();
	}
}
