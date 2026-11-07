package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** The ship rolls and gusts shove the cargo. Drag to tilt the tray and keep the parcel on it. */
class Balance extends Micro
{
	static inline var PX:Float = 270;
	static inline var PY:Float = 520;
	static inline var HALF:Float = 200;

	var tray:FlxSprite;
	var strut:FlxSprite;
	var ship:FlxSprite;
	var parcel:FlxSprite;
	var p:Float = 0;
	var vp:Float = 0;
	var input:Float = 0;
	var angle:Float = 0;
	var t:Float;
	var amp:Float;
	var gust:Float;
	var gustEvery:Float;
	var gustPower:Float;
	var fallen:Bool = false;
	var fallV:Float = 0;
	var fallY:Float = 0;
	var cheered:Bool = false;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [8, 9, 10][level]);
		survive = true;
	}

	override function setup():Void
	{
		amp = [11, 13, 15][level];
		gustEvery = [1.1, 0.95, 0.85][level];
		gustPower = [140, 170, 195][level];
		gust = gustEvery * 0.6;
		t = FlxG.random.float(0, 6.28);

		ship = heroShip();
		strut = Art.beam(8);
		strut.color = 0xFF5A5468;
		add(strut);
		tray = Art.sprite("baltray", Std.int(HALF * 2), 30, function(g)
		{
			Art.fill(g, G.KRAFT);
			Art.line(g, 3, G.INK);
			g.drawRect(2, 8, HALF * 2 - 4, 18);
			g.endFill();
			g.lineStyle();
			for (i in 0...3)
			{
				Art.fill(g, i % 2 == 0 ? G.YELLOW : G.INK);
				g.drawRect(4 + i * 14, 10, 14, 14);
				g.drawRect(HALF * 2 - 18 - i * 14, 10, 14, 14);
				g.endFill();
			}
		}, 0);
		add(tray);
		parcel = Art.parcel();
		add(parcel);
		place();
	}

	function place():Void
	{
		Art.center(tray, PX, PY);
		tray.angle = angle;
		var rad = angle * Math.PI / 180;
		if (!fallen)
		{
			var ox = Math.cos(rad) * p + Math.sin(rad) * 44;
			var oy = Math.sin(rad) * p - Math.cos(rad) * 44;
			Art.center(parcel, PX + ox, PY + oy);
			parcel.angle = angle;
		}
		ship.angle = angle * 0.4;
		Art.center(ship, PX, PY + 190);
		flameTo(ship, 1);
		Art.setBeam(strut, PX, PY, Art.cx(ship), Art.cy(ship) - 30);
	}

	override function tick(elapsed:Float):Void
	{
		var dt = elapsed * speed;
		t += dt * 2.1;
		var target = 0.0;
		if (live())
		{
			if (FlxG.mouse.pressed)
				target = Math.max(-26, Math.min(26, (px - PX) / 220 * 26));
			if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A)
				target = -20;
			if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D)
				target = 20;
		}
		input += (target - input) * Math.min(1, elapsed * 12);
		angle = Math.sin(t) * amp + input;

		if (live())
		{
			gust -= dt;
			if (gust <= 0)
			{
				gust = gustEvery * FlxG.random.float(0.8, 1.2);
				var dir = FlxG.random.bool(50) ? 1 : -1;
				vp += dir * gustPower;
				Audio.sfx("thrust", 1.5);
				for (i in 0...5)
					fx.puff(PX - dir * 260, PY + FlxG.random.float(-110, 10), G.CYAN, dir * 700, 0, 0.5, 0.35);
			}
			vp += 1000 * Math.sin(angle * Math.PI / 180) * dt;
			vp *= Math.pow(0.35, dt);
			p += vp * dt;
			if (Math.abs(p) > HALF - 12)
			{
				fallen = true;
				fallV = vp;
				Audio.sfx("denied");
				lose();
			}
		}
		if (fallen)
		{
			fallY += 1500 * elapsed;
			parcel.x += fallV * elapsed;
			parcel.y += fallY * elapsed;
			parcel.angle += fallV * elapsed;
		}
		place();
		if (finished && won && !cheered)
		{
			cheered = true;
			cheer(Art.cx(parcel), Art.cy(parcel));
		}
	}
}
