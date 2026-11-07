package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** The hold is dark. Sweep the scanner over the crates until you find the parcel. */
class Scan extends Micro
{
	var crates:Array<FlxSprite> = [];
	var target:FlxSprite;
	var scanner:FlxSprite;
	var lockRing:FlxSprite;
	var mx:Float;
	var my:Float;
	var radius:Float;
	var lock:Float = 0;
	var need:Float;
	var t:Float = 0;
	var pulse:Float = 0;
	var beep:Float = 0;

	public function new(level:Int, speed:Float)
	{
		// Searching is about looking, not reflexes, so warp only half applies.
		super(level, 1 + (speed - 1) * 0.5, [11, 12, 13][level]);
	}

	override function setup():Void
	{
		radius = [170, 140, 120][level];
		need = 0.3;
		var box = Art.panel(500, 640, 0x070C20, 0x3A4A80, 0.95, 24, 3);
		Art.center(box, G.W / 2, 500);
		add(box);

		mx = Math.max(40, Math.min(G.W - 40, px));
		my = Math.max(200, Math.min(800, py));
		var cells:Array<{x:Float, y:Float}> = [];
		for (r in 0...4)
			for (c in 0...3)
				cells.push({x: 110 + c * 160 + FlxG.random.float(-18, 18), y: 260 + r * 160 + FlxG.random.float(-18, 18)});
		var far = cells.filter(function(p) return Micro.dist(p.x, p.y, mx, my) > 220);
		if (far.length == 0)
			far = cells;
		var pick = FlxG.random.getObject(far);
		for (p in cells)
		{
			var s:FlxSprite;
			if (p == pick)
			{
				s = Art.parcel();
				target = s;
			}
			else
			{
				s = Art.sprite("scancrate", 84, 72, function(g)
				{
					Art.fill(g, 0x5A5468);
					Art.line(g, 3, G.INK);
					g.drawRect(2, 2, 80, 68);
					g.endFill();
					Art.line(g, 3, 0x3A3448);
					Art.poly(g, [2, 2, 82, 70], false);
					Art.poly(g, [82, 2, 2, 70], false);
				}, 0);
			}
			Art.center(s, p.x, p.y);
			s.alpha = 0;
			crates.push(s);
			add(s);
		}
		lockRing = new FlxSprite();
		lockRing.loadGraphic(Art.ring());
		lockRing.antialiasing = false;
		lockRing.color = G.GREEN;
		lockRing.visible = false;
		add(lockRing);
		scanner = new FlxSprite();
		scanner.loadGraphic(Art.ring());
		scanner.antialiasing = false;
		scanner.color = G.CYAN;
		add(scanner);
		place();
	}

	function place():Void
	{
		var s = radius / 62;
		scanner.scale.set(s, s);
		Art.center(scanner, mx, my);
		for (c in crates)
		{
			var d = Micro.dist(Art.cx(c), Art.cy(c), mx, my) / radius;
			var a = Math.max(0, 1 - d * d);
			// On the easiest level the parcel's beacon glints faintly through the dark.
			if (c == target && level == 0)
				a = Math.max(a, pulse);
			c.alpha = finished ? 1 : a;
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		pulse = Math.max(0, Math.sin(t * 5) - 0.75) * 1.6;
		if (FlxG.mouse.pressed || FlxG.mouse.justMoved)
		{
			mx = px;
			my = py;
		}
		if (live())
		{
			var on = Micro.dist(mx, my, Art.cx(target), Art.cy(target)) < 70;
			if (on)
			{
				lock += elapsed;
				beep -= elapsed;
				if (beep <= 0)
				{
					beep = 0.08;
					Audio.sfx("lock");
				}
			}
			else
				lock = Math.max(0, lock - elapsed * 2);
			var p = lock / need;
			lockRing.visible = p > 0;
			var rs = (110 - 50 * Math.min(1, p)) / 62;
			lockRing.scale.set(rs, rs);
			Art.center(lockRing, Art.cx(target), Art.cy(target));
			if (lock >= need)
			{
				Audio.sfx("locked");
				cheer(Art.cx(target), Art.cy(target));
				win();
			}
		}
		else
			lockRing.visible = false;
		place();
	}
}
