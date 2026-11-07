package games;

import core.Art;
import core.Audio;
import core.G;
import core.Juice;
import core.PixelText;
import core.Ui;
import flixel.FlxG;
import flixel.FlxSprite;

/** Watch the lock flash its code, then tap the same keys back in order. */
class Keypad extends Micro
{
	static inline var GX:Float = 150;
	static inline var GY:Float = 420;
	static inline var CW:Float = 120;
	static inline var CH:Float = 110;

	var keys:Array<FlxSprite> = [];
	var leds:Array<FlxSprite> = [];
	var code:Array<Int> = [];
	var step:Float;
	var t:Float = 0;
	var entered:Int = 0;
	var watching:Bool = true;
	var lastShown:Int = -1;
	var flashT:Array<Float> = [];
	var status:PixelText;

	public function new(level:Int, speed:Float)
	{
		// Memory doesn't get faster with warp, so only half of it applies here.
		super(level, 1 + (speed - 1) * 0.5, [12, 14, 16][level]);
	}

	override function setup():Void
	{
		var n = [3, 4, 5][level];
		step = [0.95, 0.85, 0.75][level] * beat;
		var box = Art.panel(440, 560, 0x070C20, 0x3A4A80, 0.9, 20, 3);
		Art.center(box, G.W / 2, 460);
		add(box);
		for (i in 0...9)
		{
			var k = Art.sprite("keybtn", 104, 94, function(g)
			{
				Art.fill(g, 0xFFFFFF);
				Art.line(g, 3, G.INK);
				Art.chamfer(g, 2, 2, 100, 90, 10);
				g.endFill();
			}, 0);
			var x = GX + (i % 3) * CW;
			var y = GY + Std.int(i / 3) * CH;
			Art.center(k, x, y);
			k.color = G.KRAFT;
			keys.push(k);
			flashT.push(0);
			add(k);
			var label = Ui.text(x - 40, y - 16, 80, Std.string(i + 1), 32, G.INK);
			add(label);
		}
		var last = -1;
		for (i in 0...n)
		{
			var d = FlxG.random.int(0, 8, [last]);
			last = d;
			code.push(d);
			var led = Art.sprite("keyled", 28, 28, function(g)
			{
				Art.fill(g, 0xFFFFFF);
				Art.line(g, 3, G.INK);
				g.drawCircle(14, 14, 11);
				g.endFill();
			}, 0);
			led.color = 0xFF5A5468;
			Art.center(led, G.W / 2 + (i - (n - 1) / 2) * 46, 330);
			leds.push(led);
			add(led);
		}
		status = Ui.text(0, 262, G.W, "Watch", 24, G.YELLOW);
		add(status);
	}

	function light(i:Int, pitch:Float):Void
	{
		flashT[i] = Math.min(step * 0.7, 0.3);
		Audio.sfx("beep", pitch);
	}

	override function tick(elapsed:Float):Void
	{
		t += elapsed;
		for (i in 0...keys.length)
		{
			flashT[i] = Math.max(0, flashT[i] - elapsed);
			var on = flashT[i] > 0;
			keys[i].color = on ? G.ORANGE : G.KRAFT;
			var s = on ? 1.08 : 1.0;
			keys[i].scale.set(s, s);
		}

		if (watching)
		{
			var idx = Std.int((t - beat) / step);
			if (t >= beat && idx != lastShown && idx < code.length)
			{
				lastShown = idx;
				light(code[idx], 1 + idx * 0.12);
			}
			if (t >= beat + code.length * step)
			{
				watching = false;
				status.text = "Your turn";
				status.color = G.GREEN;
				Ui.pop(cast status, 0.3);
			}
			return;
		}

		if (!tapped())
			return;
		var hit = -1;
		for (i in 0...keys.length)
			if (Math.abs(px - Art.cx(keys[i])) < CW / 2 && Math.abs(py - Art.cy(keys[i])) < CH / 2)
				hit = i;
		if (hit < 0)
			return;
		if (hit == code[entered])
		{
			light(hit, 1 + entered * 0.12);
			leds[entered].color = G.GREEN;
			Juice.small(Art.cx(keys[hit]), Art.cy(keys[hit]), G.CYAN);
			entered++;
			if (entered >= code.length)
			{
				Audio.sfx("locked");
				status.text = "Accepted";
				cheer(G.W / 2, 330);
				win();
			}
		}
		else
		{
			Audio.sfx("denied");
			keys[hit].color = G.RED;
			flashT[code[entered]] = 0.6;
			status.text = "Wrong key";
			status.color = G.RED;
			fx.burst(Art.cx(keys[hit]), Art.cy(keys[hit]), G.RED, 14, 240, 0.4, 0.6);
			lose();
		}
	}
}
