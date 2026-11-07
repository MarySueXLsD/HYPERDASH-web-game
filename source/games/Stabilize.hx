package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Hold to charge the reactor, release while the needle is inside the green zone. */
class Stabilize extends Micro
{
	static inline var TOP:Float = 200;
	static inline var BOT:Float = 780;
	static inline var GX:Float = 390;

	var core:FlxSprite;
	var coreGlow:FlxSprite;
	var fill:FlxSprite;
	var zone:FlxSprite;
	var needle:FlxSprite;
	var charge:Float = 0;
	var zoneLo:Float;
	var zoneHi:Float;
	var rate:Float;
	var charging:Bool = false;
	var t:Float = 0;
	var buzz:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 7);
	}

	override function setup():Void
	{
		var size = [0.22, 0.16, 0.11][level];
		var mid = FlxG.random.float(0.5, 0.85);
		zoneLo = mid - size / 2;
		zoneHi = mid + size / 2;
		rate = 1 / (duration * 0.42);

		coreGlow = new FlxSprite();
		coreGlow.loadGraphic(Art.dot());
		coreGlow.blend = openfl.display.BlendMode.ADD;
		coreGlow.color = G.CYAN;
		add(coreGlow);
		core = Art.sprite("reactor", 180, 180, function(g)
		{
			Art.fill(g, 0x0A1430);
			Art.line(g, 4, 0xEAF6FF);
			Art.poly(g, Art.hexPts(90, 90, 86, Math.PI / 6));
			g.endFill();
			Art.line(g, 3, G.CYAN);
			g.drawCircle(90, 90, 52);
			Art.line(g, 2, G.CYAN, 0.5);
			g.drawCircle(90, 90, 36);
			g.lineStyle();
			Art.fill(g, G.CYAN);
			g.drawCircle(90, 90, 22);
			g.endFill();
		}, 1, 10);
		Art.center(core, 170, 490);
		add(core);

		var track = Art.panel(90, Std.int(BOT - TOP + 20), 0x050818, 0x3A4A80, 0.9, 12, 3);
		Art.center(track, GX, (TOP + BOT) / 2);
		add(track);
		zone = new FlxSprite().makeGraphic(70, Std.int((zoneHi - zoneLo) * (BOT - TOP)), 0xFF4DFF9A);
		zone.alpha = 0.35;
		zone.setPosition(GX - 35, yOf(zoneHi));
		add(zone);
		var zl = Art.beam(3);
		zl.color = G.GREEN;
		Art.setBeam(zl, GX - 50, yOf(zoneHi), GX + 50, yOf(zoneHi));
		add(zl);
		var zl2 = Art.beam(3);
		zl2.color = G.GREEN;
		Art.setBeam(zl2, GX - 50, yOf(zoneLo), GX + 50, yOf(zoneLo));
		add(zl2);
		fill = new FlxSprite().makeGraphic(62, Std.int(BOT - TOP), 0xFFFFFFFF);
		fill.origin.set(31, BOT - TOP);
		fill.setPosition(GX - 31, TOP);
		add(fill);
		needle = Art.beam(6);
		add(needle);
		paint();
	}

	inline function yOf(v:Float):Float
	{
		return BOT - v * (BOT - TOP);
	}

	function paint():Void
	{
		fill.scale.y = Math.max(0.001, charge);
		var inZone = charge >= zoneLo && charge <= zoneHi;
		fill.color = inZone ? G.GREEN : (charge > zoneHi ? G.RED : G.CYAN);
		Art.setBeam(needle, GX - 70, yOf(charge), GX + 70, yOf(charge));
		needle.color = inZone ? G.GREEN : G.WHITE;
		var s = 1 + charge * 0.15 + (charging ? Math.sin(t * 40) * 0.02 * charge : 0);
		core.scale.set(s, s);
		core.angle += charge * 6;
		core.color = charge > zoneHi ? 0xFFFFA0A0 : 0xFFFFFFFF;
		var gs = 4 + charge * 6;
		coreGlow.scale.set(gs, gs);
		Art.center(coreGlow, Art.cx(core), Art.cy(core));
		coreGlow.alpha = 0.25 + charge * 0.5;
		coreGlow.color = charge > zoneHi ? G.RED : (inZone ? G.GREEN : G.CYAN);
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		charging = held();
		if (charging)
		{
			var r = rate * (level == 2 ? 0.7 + charge * 1.2 : 1);
			charge += r * elapsed;
			buzz -= elapsed;
			if (buzz <= 0)
			{
				buzz = 0.06;
				Audio.sfx("charge", 0.7 + charge * 1.6);
			}
			if (FlxG.random.bool(50))
				fx.puff(Art.cx(core) + FlxG.random.float(-70, 70), Art.cy(core) + FlxG.random.float(-70, 70), G.CYAN, 0, 0, 0.4, 0.3);
			if (charge >= 1)
			{
				charge = 1;
				boom(Art.cx(core), Art.cy(core), G.RED);
				core.visible = false;
				lose();
			}
		}
		if (released() && charge > 0)
		{
			if (charge >= zoneLo && charge <= zoneHi)
			{
				Audio.sfx("locked");
				cheer(Art.cx(core), Art.cy(core));
				cheer(GX, yOf(charge));
				win();
			}
			else
			{
				Audio.sfx("denied");
				fx.burst(GX, yOf(charge), G.RED, 14, 240, 0.4, 0.6);
				lose();
			}
		}
		paint();
	}
}
