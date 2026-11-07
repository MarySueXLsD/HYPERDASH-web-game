package states;

import core.Input;
import core.Art;
import core.Audio;
import core.G;
import core.Ui;
import core.VecFont;
import flixel.FlxG;
import flixel.FlxSprite;
import core.PixelText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

/** "Tap to start" gate (browsers need a gesture before audio) followed by the studio splash. */
class BootState extends BaseState
{
	var prompt:PixelText;
	var started:Bool = false;
	var t:Float = 0;

	override function build():Void
	{
		stars.rate = 0.05;
		stars.stretch = 0;
		prompt = Ui.text(0, G.H / 2 - 20, G.W, "Tap to start", 26, G.DIM);
		add(prompt);
		var hint = Ui.text(0, G.H - 80, G.W, "Best with sound on", 16, 0xFF6A6488);
		add(hint);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		t += elapsed;
		if (!started)
		{
			prompt.alpha = 0.5 + 0.5 * Math.sin(t * 4);
			if (Input.justPressed || FlxG.keys.justPressed.ANY)
				begin();
		}
	}

	function begin():Void
	{
		started = true;
		Audio.unlock();
		Audio.sfx("warp");
		FlxTween.tween(prompt, {alpha: 0}, 0.2);
		forEachOfType(PixelText, function(t) FlxTween.tween(t, {alpha: 0}, 0.2));
		stars.rate = 1.2;
		stars.stretch = 0.6;
		kick(1.5);

		var logo = Ui.stamp("SLAPJAM", 56, G.ORANGE, G.W / 2, G.H / 2 - 30, true, -6);
		add(logo);
		Ui.slam(logo, 0.15, 2.4, 0.4, function()
		{
			Audio.sfx("slam");
			core.Juice.shake(0.35);
		});
		var sub = Ui.text(0, G.H / 2 + 40, G.W, "presents a delivery", 18, G.DIM);
		add(sub);
		Ui.fadeIn(sub, 0.5);

		// Bake the heavy art while the splash is up so nothing hitches later.
		var jobs = preloadJobs();
		new FlxTimer().start(0.6, function(_)
		{
			new FlxTimer().start(0.02, function(_) if (jobs.length > 0) jobs.shift()(), jobs.length);
		});
		new FlxTimer().start(2.2, function(_) go(TitleState.new));
	}

	static function preloadJobs():Array<Void->Void>
	{
		var jobs:Array<Void->Void> = [
			() -> Art.ship(),
			() -> { for (p in core.Pilots.ALL) core.Pilots.ship(p); },
			() -> Art.flame(),
			() -> Art.station(),
			() -> Art.blackHole(),
			() -> Art.planet(),
			() -> Art.pirate(),
			() -> Art.drone()
		];
		for (who in ["NOVA", "PIP", "DISPATCH", "RUST", "ZIB", "VEX", "KADE"])
		{
			jobs.push(() -> Art.portrait(who, false));
			jobs.push(() -> Art.portrait(who, true));
		}
		return jobs;
	}
}
