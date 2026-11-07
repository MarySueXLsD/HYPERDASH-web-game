package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Hold the reticle over the corsair until the lock completes. */
class LockOn extends Micro
{
	var target:FlxSprite;
	var reticle:FlxSprite;
	var ring:FlxSprite;
	var missile:FlxSprite;
	var lock:Float = 0;
	var need:Float;
	var radius:Float;
	var t:Float = 0;
	var a:Float;
	var b:Float;
	var tx:Float = G.W / 2;
	var ty:Float = 400;
	var beepT:Float = 0;
	var mx:Float;
	var my:Float;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 8);
	}

	override function setup():Void
	{
		need = duration * 0.38;
		radius = [85, 70, 58][level];
		a = FlxG.random.float(0, 6.28);
		b = FlxG.random.float(0, 6.28);
		target = Art.pirate();
		add(target);
		ring = new FlxSprite();
		ring.loadGraphic(Art.ring());
		ring.antialiasing = false;
		add(ring);
		reticle = Art.sprite("reticle", 120, 120, function(g)
		{
			Art.line(g, 3, 0xFFFFFF);
			g.drawCircle(60, 60, 34);
			for (k in 0...4)
			{
				var ang = k * Math.PI / 2;
				Art.poly(g, [60 + Math.cos(ang) * 44, 60 + Math.sin(ang) * 44, 60 + Math.cos(ang) * 58, 60 + Math.sin(ang) * 58], false);
			}
			g.lineStyle();
			Art.fill(g, 0xFFFFFF);
			g.drawCircle(60, 60, 3);
			g.endFill();
		}, 1, 6);
		add(reticle);
		mx = G.W / 2;
		my = 760;
		place(0);
	}

	function place(elapsed:Float):Void
	{
		var sp = [0.9, 1.3, 1.7][level] * speed;
		if (!finished)
		{
			tx = G.W / 2 + Math.sin(t * sp + a) * 180 + Math.sin(t * sp * 2.3) * (level * 30);
			ty = 440 + Math.cos(t * sp * 0.8 + b) * 220;
		}
		Art.center(target, tx, ty);
		target.angle = Math.sin(t * sp) * 10;
		if (FlxG.mouse.pressed || FlxG.mouse.justMoved)
		{
			mx = px;
			my = py;
		}
		Art.center(reticle, mx, my);
		var on = isOn();
		reticle.color = on ? G.RED : G.WHITE;
		reticle.angle += elapsed * (on ? 400 : 60);
		var p = lock / need;
		ring.visible = p > 0 && !finished;
		var s = (radius + 60 * (1 - p)) / 60;
		ring.scale.set(s, s);
		Art.center(ring, tx, ty);
		ring.color = p > 0.75 ? G.RED : G.YELLOW;
		ring.alpha = 0.4 + p * 0.6;
	}

	inline function isOn():Bool
	{
		return held() && Micro.dist(mx, my, tx, ty) < radius;
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		if (live())
		{
			if (isOn())
			{
				lock += elapsed;
				beepT -= elapsed;
				if (beepT <= 0)
				{
					beepT = 0.12 * (1 - lock / need * 0.6);
					Audio.sfx("lock");
				}
			}
			else
				lock = Math.max(0, lock - elapsed * 0.5);
			if (lock >= need)
			{
				Audio.sfx("locked");
				missile = Art.beam(6);
				missile.color = G.YELLOW;
				add(missile);
				Art.setBeam(missile, G.W / 2, G.H, tx, ty);
				boom(tx, ty, G.ORANGE);
				target.visible = false;
				win();
			}
		}
		if (missile != null)
			missile.alpha -= elapsed * 3;
		place(elapsed);
	}
}
