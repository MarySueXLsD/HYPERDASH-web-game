package games;

import core.Art;
import core.Juice;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** The ship slides side to side. Tap to launch it into the docking port. */
class Dock extends Micro
{
	var ship:FlxSprite;
	var port:FlxSprite;
	var hull:FlxSprite;
	var guide:FlxSprite;
	var lightsL:FlxSprite;
	var lightsR:FlxSprite;
	var t:Float = 0;
	var launched:Bool = false;
	var shipX:Float = G.W / 2;
	var shipY:Float = 800;
	var portX:Float = G.W / 2;
	var tol:Float;
	var phase0:Float;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, 6);
		tol = [44, 32, 24][level];
	}

	override function setup():Void
	{
		phase0 = FlxG.random.float(0, 6.28);
		hull = Art.sprite("dockhull", 540, 210, function(g)
		{
			Art.fill(g, 0x101830);
			Art.line(g, 3, 0x3A4A80);
			Art.poly(g, [0, 0, 540, 0, 540, 150, 400, 150, 360, 210, 180, 210, 140, 150, 0, 150]);
			g.endFill();
			Art.line(g, 2, G.CYAN, 0.6);
			for (i in 0...6)
				g.drawRect(20 + i * 86, 30, 60, 20);
		}, 1, 8);
		hull.setPosition((G.W - hull.width) / 2, 60);
		add(hull);
		port = Art.sprite("port" + tol, Std.int(tol * 2 + 60), 90, function(g)
		{
			var w = tol * 2 + 60;
			Art.fill(g, 0x000000);
			Art.line(g, 3, G.GREEN);
			Art.poly(g, [0, 0, w, 0, w - 22, 90, 22, 90]);
			g.endFill();
			Art.line(g, 2, G.GREEN, 0.5);
			Art.poly(g, [w / 2, 10, w / 2, 80], false);
		}, 1, 8);
		add(port);
		lightsL = Art.sprite("docklight", 16, 16, function(g)
		{
			Art.fill(g, 0xFFFFFF);
			g.drawCircle(8, 8, 7);
			g.endFill();
		}, 2, 6);
		lightsR = Art.sprite("docklight", 16, 16, function(g) {}, 2, 6);
		add(lightsL);
		add(lightsR);
		if (level == 0)
		{
			guide = Art.beam(2);
			guide.alpha = 0.35;
			add(guide);
		}
		ship = heroShip();
		position(0);
	}

	function position(elapsed:Float):Void
	{
		if (level == 2)
			portX = G.W / 2 + Math.sin(t * 1.2 * speed + phase0) * 80;
		port.x = portX - port.width / 2;
		port.y = 238;
		lightsL.setPosition(port.x - 18, port.y + 4);
		lightsR.setPosition(port.x + port.width + 2, port.y + 4);
		var blink = Std.int(t * 6) % 2 == 0;
		var aligned = Math.abs(shipX - portX) < tol;
		lightsL.color = lightsR.color = aligned ? G.GREEN : (blink ? G.RED : 0xFF401018);
		if (!launched)
		{
			var amp = 200.0;
			var w = (1.8 + level * 0.6) * speed;
			shipX = G.W / 2 + Math.sin(t * w + phase0) * amp;
		}
		Art.center(ship, shipX, shipY);
		if (guide != null)
		{
			Art.setBeam(guide, shipX, shipY - 60, shipX, port.y + 90);
			guide.angle = -90;
			guide.x = shipX;
			guide.y = shipY - 60 - guide.height / 2;
			guide.color = aligned ? G.GREEN : G.WHITE;
			guide.visible = !launched;
		}
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		if (tapped() && !launched)
		{
			launched = true;
			Audio.sfx("thrust", 2);
			host.kick(0.4);
		}
		if (launched && !finished)
		{
			shipY -= elapsed * 1500;
			fx.puff(shipX, shipY + 60, G.ORANGE, FlxG.random.float(-30, 30), 200, 0.7, 0.3);
			if (shipY <= port.y + 120)
			{
				if (Math.abs(shipX - portX) < tol)
				{
					shipY = port.y + 120;
					Audio.sfx("dock");
					cheer(shipX, port.y + 80);
					Juice.shake(0.25);
					win();
				}
				else
				{
					boom(shipX, shipY - 30);
					ship.visible = false;
					lose();
				}
			}
		}
		position(elapsed);
		flameTo(ship, launched ? 2.2 : 0.8);
	}
}
