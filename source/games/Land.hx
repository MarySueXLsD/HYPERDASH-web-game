package games;

import core.Art;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;
import core.PixelText;

/** Hold to fire retro thrusters and touch down below the safe speed. */
class Land extends Micro
{
	static inline var PAD:Float = 800;

	var ship:FlxSprite;
	var pad:FlxSprite;
	var meter:FlxSprite;
	var meterFill:FlxSprite;
	var safeMark:FlxSprite;
	var label:PixelText;
	var y:Float = 170;
	var vy:Float;
	var gravity:Float;
	var thrust:Float;
	var safe:Float;
	var burning:Bool = false;
	var landed:Bool = false;
	var noise:Float = 0;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 11);
	}

	override function setup():Void
	{
		gravity = [230, 260, 290][level];
		thrust = gravity * 2.3;
		safe = [270, 245, 220][level];
		vy = [50, 75, 100][level];

		var ground = Art.sprite("ground", 540, 140, function(g)
		{
			Art.fill(g, 0x140C24);
			Art.line(g, 3, G.VIOLET);
			Art.poly(g, [0, 30, 60, 20, 120, 40, 170, 10, 370, 10, 420, 34, 480, 18, 540, 30, 540, 140, 0, 140]);
			g.endFill();
		}, 1, 8);
		ground.setPosition(0, PAD + 8);
		add(ground);
		pad = Art.sprite("landpad", 200, 26, function(g)
		{
			Art.fill(g, 0x0A2A1C);
			Art.line(g, 3, G.GREEN);
			Art.chamfer(g, 0, 0, 200, 22, 8);
			g.endFill();
			g.lineStyle();
			for (i in 0...5)
			{
				Art.fill(g, i % 2 == 0 ? G.YELLOW : 0x101010);
				g.drawRect(20 + i * 32, 8, 32, 6);
			}
			g.endFill();
		}, 1, 8);
		Art.center(pad, G.W / 2, PAD + 16);
		add(pad);

		var track = Art.panel(40, 400, 0x050818, 0x3A4A80, 0.9, 8, 2);
		track.setPosition(G.W - 70, 280);
		add(track);
		meter = track;
		meterFill = new FlxSprite().makeGraphic(24, 380, 0xFFFFFFFF);
		meterFill.origin.set(12, 0);
		meterFill.setPosition(track.x + (track.width - 24) / 2, track.y + 10);
		add(meterFill);
		safeMark = Art.beam(4);
		safeMark.color = G.GREEN;
		add(safeMark);
		label = core.Ui.text(G.W - 110, 236, 120, "SPEED", 14, G.DIM);
		add(label);

		ship = heroShip();
		ship.angle = 180;
		place();
	}

	inline function maxV():Float
	{
		return 640;
	}

	function place():Void
	{
		Art.center(ship, G.W / 2, y);
		ship.angle = 0;
		flameTo(ship, 0);
		var f:FlxSprite = cast members[ship.ID];
		// Retro thrusters fire downward, so the flame sits below the ship pointing at the pad.
		f.visible = burning && ship.visible;
		f.flipY = false;
		f.angle = 0;
		f.x = Art.cx(ship) - f.width / 2;
		f.y = ship.y + ship.height - 28;
		var k = 0.9 + Math.random() * 0.5;
		f.scale.set(k * 1.3, k * 1.5);

		var v = Math.max(0, vy) / maxV();
		meterFill.scale.y = Math.max(0.001, Math.min(1, v));
		var ok = vy < safe;
		meterFill.color = ok ? G.GREEN : (vy < safe * 1.5 ? G.YELLOW : G.RED);
		var sy = meterFill.y + safe / maxV() * 380;
		Art.setBeam(safeMark, meter.x - 8, sy, meter.x + meter.width + 8, sy);
		label.color = ok ? G.GREEN : G.RED;
	}

	override function tick(elapsed:Float):Void
	{
		// Warp only half applies to the descent, so a fast run still leaves time to react.
		var dt = elapsed * (1 + (speed - 1) * 0.5);
		// Any press counts, even one that began during the prompt.
		burning = live() && (FlxG.mouse.pressed || FlxG.keys.pressed.SPACE);
		if (!landed && ship.visible)
		{
			vy += (gravity - (burning ? thrust : 0)) * dt;
			vy = Math.max(-200, vy);
			y += vy * dt;
			if (y < 140)
			{
				y = 140;
				vy = Math.max(0, vy);
			}
			if (burning)
			{
				noise -= elapsed;
				if (noise <= 0)
				{
					noise = 0.08;
					Audio.sfx("thrust");
				}
				fx.puff(G.W / 2 + FlxG.random.float(-10, 10), y + 70, G.ORANGE, FlxG.random.float(-60, 60), 500, 0.7, 0.3);
			}
			if (y + 46 >= PAD)
			{
				y = PAD - 46;
				landed = true;
				if (vy < safe && live())
				{
					Audio.sfx("dock");
					fx.burst(G.W / 2, PAD, 0xFFB8C4E0, 24, 260, 0.6, 0.7);
					cheer(G.W / 2, PAD - 40);
					win();
				}
				else
				{
					boom(G.W / 2, PAD - 20);
					ship.visible = false;
					lose();
				}
			}
		}
		place();
	}
}
