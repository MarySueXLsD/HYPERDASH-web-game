package games;

import core.Art;
import core.Juice;
import core.Audio;
import core.G;
import flixel.FlxSprite;

/** A warp ring collapses towards the target. Tap the moment they overlap. */
class Jump extends Micro
{
	static inline var CX:Float = 270;
	static inline var CY:Float = 480;
	static inline var TARGET:Float = 90;

	var target:FlxSprite;
	var ring:FlxSprite;
	var r:Float = 420;
	var tol:Float;
	var shrink:Float;
	var jumps:Int;
	var done:Int = 0;
	var pips:Array<FlxSprite> = [];
	var spokes:Array<FlxSprite> = [];
	var t:Float = 0;
	var spin:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [6, 8, 10][level]);
	}

	override function setup():Void
	{
		jumps = level + 1;
		tol = [22, 17, 13][level];
		shrink = (420 - TARGET + 60) / (duration / jumps * 0.85);

		for (i in 0...12)
		{
			var s = Art.beam(2);
			s.color = 0xFF2A3A80;
			spokes.push(s);
			add(s);
		}
		target = Art.sprite("jumptarget" + tol, Std.int((TARGET + tol) * 2 + 8), Std.int((TARGET + tol) * 2 + 8), function(g)
		{
			var c = TARGET + tol + 4;
			Art.line(g, tol * 2, G.GREEN, 0.18);
			g.drawCircle(c, c, TARGET);
			Art.line(g, 3, G.GREEN);
			g.drawCircle(c, c, TARGET);
			Art.line(g, 1.5, G.GREEN, 0.6);
			g.drawCircle(c, c, TARGET - tol);
			g.drawCircle(c, c, TARGET + tol);
		}, 1, 8);
		Art.center(target, CX, CY);
		add(target);
		var core = Art.sprite("jumpcore", 40, 40, function(g) Art.radial(g, 20, 20, 20, 0xFFFFFF, G.CYAN, 1, 0), 1, 8);
		Art.center(core, CX, CY);
		add(core);

		ring = Art.sprite("jumpring", 410, 410, function(g)
		{
			Art.line(g, 8, 0xFFFFFF);
			g.drawCircle(205, 205, 200);
		}, 2, 10);
		add(ring);

		for (i in 0...jumps)
		{
			var p = Art.hexCell(false);
			Art.center(p, CX + (i - (jumps - 1) / 2) * 50, 820);
			pips.push(p);
			add(p);
		}
		place();
	}

	function place():Void
	{
		var ts = target.scale.x + (1 - target.scale.x) * 0.2;
		target.scale.set(ts, ts);
		var s = r / 200;
		ring.scale.set(s, s);
		Art.center(ring, CX, CY);
		var close = Math.abs(r - TARGET) <= tol;
		ring.color = close ? G.GREEN : G.CYAN;
		ring.alpha = Math.min(1, (420 - r) / 60 + 0.3);
		for (i in 0...spokes.length)
		{
			var a = i / spokes.length * Math.PI * 2 + spin;
			Art.setBeam(spokes[i], CX + Math.cos(a) * 120, CY + Math.sin(a) * 120, CX + Math.cos(a) * 520, CY + Math.sin(a) * 520);
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		spin += elapsed * 0.3 * speed;
		if (!finished)
			r -= shrink * elapsed;
		if (tapped())
		{
			if (Math.abs(r - TARGET) <= tol)
			{
				pips[done].loadGraphic(Art.hexCell(true).graphic);
				done++;
				Audio.sfx("warp");
				host.stars.flash = 0.6;
				Juice.shake(0.3);
				Juice.hitStop(0.04);
				target.scale.set(1.25, 1.25);
				cheer(CX, CY, G.CYAN);
				if (done >= jumps)
					win();
				else
					r = 420;
			}
			else
			{
				Audio.sfx("denied");
				fx.shock(CX, CY, G.RED, r / 60 * 0.9);
				lose();
			}
		}
		if (live() && r < TARGET - tol)
		{
			fx.shock(CX, CY, G.RED, 1);
			Audio.sfx("denied");
			lose();
		}
		if (finished && won)
			r = Math.max(0, r - elapsed * 600);
		place();
	}
}
