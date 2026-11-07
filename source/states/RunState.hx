package states;

import core.Art;
import core.Audio;
import core.G;
import core.Input;
import core.Juice;
import core.Pilots;
import core.Run;
import core.Ui;
import core.VecFont;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import core.PixelText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import games.Catalog;
import games.Micro;

enum Phase
{
	CARD;
	BRIDGE;
	PROMPT;
	PLAY;
	RESULT;
	EXIT;
}

/** The core loop: bridge view → stamped prompt → mini game → result, faster every round. */
class RunState extends BaseState
{
	static inline var DIAL_X:Float = 270;
	static inline var DIAL_Y:Float = 704;
	static inline var FAIL_PENALTY:Float = 6;

	var run:Run;
	var phase:Phase;
	var phaseT:Float = 0;
	var phaseLen:Float = 0;

	var bridge:FlxGroup;
	var gameLayer:FlxGroup;
	var hudPlay:FlxGroup;
	var hudBridge:FlxGroup;
	var top:FlxGroup;

	var ship:FlxSprite;
	var flame:FlxSprite;
	var shipKick:Float = 0;

	var placeText:PixelText;
	var subText:PixelText;
	var tipsText:PixelText;
	var streakText:PixelText;
	var clockTag:FlxSprite;
	var clockText:PixelText;
	var routeStops:Array<FlxSprite> = [];
	var routeMarker:FlxSprite;
	var cargo:Array<FlxSprite> = [];
	var miniCargo:Array<FlxSprite> = [];
	var needle:FlxSprite;
	var needleSpeed:Float = 1;
	var warpText:PixelText;

	var fuseTrack:FlxSprite;
	var fuseFill:FlxSprite;
	var fuseSpark:FlxSprite;
	var playClock:PixelText;
	var tag:FlxSprite;
	var tagText:FlxSprite;
	var lastTick:Int = 99;
	var lastSecond:Int = 99;

	var micro:Micro;
	var info:GameInfo;
	var prompt:FlxSprite;
	var hint:PixelText;
	var hintBg:FlxSprite;
	var pauseBtn:FlxSprite;

	var lastWon:Null<Bool> = null;
	var lastGain:Int = 0;
	var lastFast:Bool = false;
	var sectorJustCleared:Bool = false;
	var shownLives:Int;
	var t:Float = 0;

	override function build():Void
	{
		run = G.run;
		if (run == null)
			run = G.run = new Run(STORY);
		shownLives = run.lives;
		needleSpeed = run.speed();

		var look = run.look();
		stars.tint(look.tintA, look.tintB, true);
		stars.center(G.W / 2, 440);
		Audio.music("run");
		Audio.setTempo(run.speed());

		bridge = new FlxGroup();
		add(bridge);
		flame = Art.flame();
		bridge.add(flame);
		ship = Pilots.ship(Pilots.get(run.pilot));
		bridge.add(ship);

		gameLayer = new FlxGroup();
		add(gameLayer);
		add(sparks);

		buildBridgeHud();
		buildPlayHud();

		top = new FlxGroup();
		add(top);

		pauseBtn = Art.sprite("pausebtn", 56, 56, function(g)
		{
			g.lineStyle();
			Art.fill(g, 0x000000, 0.45);
			Art.chamfer(g, 5, 6, 51, 50, 9);
			g.endFill();
			Art.fill(g, G.KRAFT);
			Art.line(g, 3, G.INK);
			Art.chamfer(g, 1.5, 1.5, 48, 48, 9);
			g.endFill();
			g.lineStyle();
			Art.fill(g, G.INK);
			g.drawRect(16, 14, 7, 22);
			g.drawRect(28, 14, 7, 22);
			g.endFill();
		}, 0);
		pauseBtn.setPosition(G.W - 70, 16);
		add(pauseBtn);

		hudPlay.visible = false;
		if (run.round == 0 && run.mode != TRAINING)
			enterCard();
		else
			enterBridge();
	}

	// ------------------------------------------------------------- HUD build

	function buildBridgeHud():Void
	{
		hudBridge = new FlxGroup();
		add(hudBridge);

		placeText = Ui.text(24, 24, 360, "", 18, G.WHITE, "left");
		hudBridge.add(placeText);
		subText = Ui.text(24, 54, 360, "", 16, 0xFFC9C2DE, "left");
		hudBridge.add(subText);
		tipsText = Ui.text(G.W - 330, 82, 306, "", 26, G.YELLOW, "right");
		hudBridge.add(tipsText);
		streakText = Ui.text(G.W - 330, 116, 306, "", 16, G.ORANGE, "right");
		hudBridge.add(streakText);

		if (run.hasClock)
		{
			clockTag = Art.label(236, 62, G.KRAFT);
			clockTag.setPosition(20, 92);
			hudBridge.add(clockTag);
			clockText = Ui.text(clockTag.x + 36, clockTag.y + 12, 180, "", 26, G.INK, "center");
			hudBridge.add(clockText);
		}

		if (run.mode != TRAINING)
		{
			var count = Run.PER_SECTOR + 1;
			var x0 = 64.0;
			var x1 = G.W - 64.0;
			var road = Art.sprite("route", Std.int(x1 - x0), 6, function(g)
			{
				g.lineStyle();
				Art.fill(g, G.DIM, 0.6);
				var x = 0.0;
				while (x < x1 - x0)
				{
					g.drawRect(x, 1, 10, 4);
					x += 18;
				}
				g.endFill();
			}, 0);
			road.setPosition(x0, 200 - road.height / 2);
			hudBridge.add(road);
			for (i in 0...count)
			{
				var boss = i == count - 1;
				var d = new FlxSprite();
				d.antialiasing = false;
				Art.center(d, x0 + (x1 - x0) * i / (count - 1), 200);
				d.ID = boss ? 1 : 0;
				routeStops.push(d);
				hudBridge.add(d);
			}
			routeMarker = Art.sprite("routemarker", 22, 18, function(g)
			{
				g.lineStyle();
				Art.fill(g, G.ORANGE);
				Art.poly(g, [0, 0, 22, 0, 11, 18]);
				g.endFill();
			}, 0);
			hudBridge.add(routeMarker);
		}

		var dial = Art.dial(74);
		Art.center(dial, DIAL_X, DIAL_Y);
		hudBridge.add(dial);
		needle = Art.needle(56);
		needle.x = DIAL_X - needle.origin.x;
		needle.y = DIAL_Y - needle.origin.y;
		hudBridge.add(needle);
		// The reading sits under the gauge so the needle never sweeps across it.
		warpText = Ui.text(DIAL_X - 120, DIAL_Y + 84, 240, "", 24, G.WHITE);
		hudBridge.add(warpText);

		var gap = 58;
		var cx0 = G.W / 2 - (run.maxLives - 1) * gap / 2;
		for (i in 0...run.maxLives)
		{
			var c = new FlxSprite();
			c.loadGraphic(Art.cargo(i < run.lives));
			c.antialiasing = false;
			Art.center(c, cx0 + i * gap, 846);
			cargo.push(c);
			hudBridge.add(c);
		}
	}

	function buildPlayHud():Void
	{
		hudPlay = new FlxGroup();
		add(hudPlay);
		fuseTrack = Art.panel(484, 24, G.INK, G.KRAFT, 0.95, 6, 3);
		Art.center(fuseTrack, G.W / 2, 926);
		hudPlay.add(fuseTrack);
		fuseFill = new FlxSprite().makeGraphic(466, 10, 0xFFFFFFFF);
		fuseFill.origin.set(0, 5);
		fuseFill.setPosition(G.W / 2 - 233, 921);
		hudPlay.add(fuseFill);
		fuseSpark = new FlxSprite();
		fuseSpark.loadGraphic(Art.dot());
		fuseSpark.blend = openfl.display.BlendMode.ADD;
		hudPlay.add(fuseSpark);
		if (run.hasClock)
		{
			playClock = Ui.text(G.W - 260, 886, 236, "", 18, G.KRAFT, "right");
			hudPlay.add(playClock);
		}
		for (i in 0...run.maxLives)
		{
			var c = new FlxSprite();
			c.loadGraphic(Art.cargo(i < run.lives, true));
			c.setPosition(16 + i * 28, 880);
			miniCargo.push(c);
			hudPlay.add(c);
		}
	}

	function refreshHud():Void
	{
		var s = run.look();
		switch (run.mode)
		{
			case STORY:
				placeText.text = s.name;
				subText.text = 'Sector ${run.sector + 1}/${run.sectorCount}, ${Pilots.get(run.pilot).name.split(" ").pop()}';
			case ENDLESS:
				placeText.text = s.name;
				subText.text = 'Endless, job ${run.played + 1}';
			case TRAINING:
				var name = info != null ? info.blurb : Catalog.get(run.trainingId).blurb;
				placeText.text = "Training";
				subText.text = name;
		}
		tipsText.text = G.thousands(run.score) + " cr";
		streakText.text = run.streak >= 3 ? 'Streak of ${run.streak}' : "";
		paintClock();

		for (i in 0...routeStops.length)
		{
			var d = routeStops[i];
			var boss = d.ID == 1;
			var state = i < run.round ? (run.results[i] ? 1 : 2) : 0;
			var key = 'stop_${boss}_$state';
			d.loadGraphic(Art.graphic(key, boss ? 34 : 24, boss ? 34 : 24, function(g)
			{
				var r = boss ? 15.0 : 10.0;
				var c = boss ? 17.0 : 12.0;
				var fillC = state == 1 ? G.STAMP_GREEN : (state == 2 ? G.STAMP_RED : (boss ? G.YELLOW : G.PAPER));
				Art.fill(g, fillC);
				Art.line(g, 3, G.INK);
				if (boss)
					Art.chamfer(g, c - r, c - r, r * 2, r * 2, 5);
				else
					g.drawCircle(c, c, r);
				g.endFill();
			}, 0));
			var cx = d.ID == 1 ? 17 : 12;
			d.x = (64 + (G.W - 128) * i / (routeStops.length - 1)) - cx - (d.width - cx * 2) / 2;
			d.y = 200 - d.height / 2;
		}
		if (routeMarker != null)
		{
			var i = Std.int(Math.min(run.round, routeStops.length - 1));
			var tx = 64 + (G.W - 128) * i / (routeStops.length - 1);
			FlxTween.cancelTweensOf(routeMarker);
			FlxTween.tween(routeMarker, {x: tx - routeMarker.width / 2}, 0.5, {ease: FlxEase.backOut});
			routeMarker.y = 168;
		}

		for (i in 0...cargo.length)
		{
			var intact = i < run.lives;
			miniCargo[i].loadGraphic(Art.cargo(intact, true));
			if (i >= shownLives || intact)
				cargo[i].loadGraphic(Art.cargo(intact));
		}
	}

	function paintClock():Void
	{
		if (!run.hasClock)
			return;
		var label = run.late ? "LATE" : G.clock(run.guarantee).substr(0, -1);
		var col = run.late || run.guarantee < 15 ? G.STAMP_RED : G.INK;
		if (clockText != null)
		{
			clockText.text = label;
			clockText.color = col;
		}
		if (playClock != null)
		{
			playClock.text = run.late ? "Late: it's free" : label + " left";
			playClock.color = run.late || run.guarantee < 15 ? G.RED : G.KRAFT;
		}
	}

	function setNeedle(speed:Float, animate:Bool):Void
	{
		var from = needleSpeed;
		needleSpeed = speed;
		warpText.text = "warp " + G.fixed(speed);
		if (!animate)
		{
			needle.angle = needleAngle(speed);
			return;
		}
		FlxTween.num(from, speed, 0.9, {ease: FlxEase.elasticOut}, function(v) needle.angle = needleAngle(v));
		if (speed > from + 0.001)
			Ui.pop(cast warpText, 0.3);
	}

	static function needleAngle(speed:Float):Float
	{
		var tt = Math.max(-0.05, Math.min(1.08, (speed - 1) / 2));
		return 135 + 270 * tt;
	}

	// ---------------------------------------------------------------- phases

	function setPhase(p:Phase, len:Float):Void
	{
		phase = p;
		phaseT = 0;
		phaseLen = len;
	}

	function enterCard():Void
	{
		setPhase(CARD, 2.8);
		hudBridge.visible = true;
		refreshHud();
		setNeedle(run.speed(), false);
		var s = run.look();

		var tk = Art.ticket(470, 300);
		Art.center(tk, G.W / 2, 420);
		top.add(tk);
		var kicker = run.mode == ENDLESS ? 'Next zone' : 'Sector ${run.sector + 1} of ${run.sectorCount}';
		var k = Ui.text(tk.x + 30, tk.y + 34, 400, kicker, 18, G.INK, "left");
		top.add(k);
		var n = VecFont.sprite(s.name, VecFont.fit(s.name, 42, 400), G.INK, 0.12, 0, 6);
		n.setPosition(tk.x + 30, tk.y + 72);
		top.add(n);
		var sub = Ui.text(tk.x + 30, tk.y + 86 + n.height, 410, s.sub + ".", 18, 0xFF5A5468, "left");
		top.add(sub);
		for (m in [tk, k, n, sub])
		{
			var tx = m.x;
			m.x += G.W;
			FlxTween.tween(m, {x: tx}, 0.45, {ease: FlxEase.backOut});
		}
		new FlxTimer().start(0.35, function(_)
		{
			Audio.sfx("slam");
			Juice.shake(0.25);
		});
		stars.stretch = 0.9;
		stars.rate = 2.5;
		if (run.sector > 0 || run.mode == ENDLESS && run.played > 0)
		{
			var su = Ui.stamp("SPEED UP", 46, G.YELLOW, G.W / 2 + 40, 600, true, -8);
			top.add(su);
			Ui.slam(su, 0.8, 2.6, 0.4, function()
			{
				Audio.sfx("speedup");
				Juice.shake(0.45);
				sparks.burst(G.W / 2 + 40, 600, G.YELLOW, 24, 380, 0.5, 0.6);
				setNeedle(run.speed(), true);
			});
		}
		new FlxTimer().start(2.45, function(_)
		{
			for (m in top.members)
				if (m != null)
				{
					var spr:FlxSprite = cast m;
					FlxTween.tween(spr, {x: spr.x - G.W, alpha: 0}, 0.3, {ease: FlxEase.quartIn});
				}
		});
	}

	function enterBridge():Void
	{
		clearTop();
		var boss = run.isBoss();
		var len = G.beat(run.speed()) * (boss ? 6 : 3);
		if (lastWon == null)
			len += 0.4;
		setPhase(BRIDGE, len);
		Audio.setTempo(run.speed());
		Audio.music(boss ? "boss" : "run");
		bridge.visible = true;
		hudBridge.visible = true;
		hudPlay.visible = false;
		stars.stretch = 0.2 + (run.speed() - 1) * 0.45;
		stars.rate = 0.6 * run.speed();
		refreshHud();
		setNeedle(run.speed(), true);
		Ui.fadeIn(ship, 0, 0.3, 120);

		if (lastWon == true)
		{
			shipKick = 1;
			var pop = Ui.text(G.W - 260, 142, 236, "+" + G.thousands(lastGain) + " cr", 22, G.YELLOW, "right");
			top.add(pop);
			Ui.pop(cast pop, 0.4);
			FlxTween.tween(pop, {alpha: 0}, 0.4, {startDelay: 1.0});
			Ui.pop(cast tipsText, 0.25);
			if (lastFast)
			{
				var f = Ui.text(G.W - 384, 176, 360, "Fast delivery tip", 16, G.ORANGE, "right");
				top.add(f);
				FlxTween.tween(f, {alpha: 0}, 0.4, {startDelay: 1.0});
			}
			Audio.sfx("coin", 1 + Math.min(run.streak, 8) * 0.06);
		}
		else if (lastWon == false)
		{
			var i = run.lives;
			if (i >= 0 && i < cargo.length)
			{
				var c = cargo[i];
				new FlxTimer().start(0.25, function(_)
				{
					c.loadGraphic(Art.cargo(false));
					Ui.pop(c, 0.5);
					Juice.small(Art.cx(c), Art.cy(c), G.RED);
					Audio.sfx("hit");
				});
			}
			shownLives = run.lives;
		}
		sectorJustCleared = false;

		if (boss)
		{
			for (yy in [250.0, 330.0])
			{
				var hz = Art.hazard(G.W + 40, 26);
				hz.setPosition(-20, yy);
				top.add(hz);
				var tx = hz.x;
				hz.x = yy < 300 ? -G.W : G.W;
				FlxTween.tween(hz, {x: tx}, 0.4, {ease: FlxEase.backOut, startDelay: 0.3});
			}
			var warn = Ui.stamp("BOSS", 50, G.STAMP_RED, G.W / 2, 296, true, 5);
			top.add(warn);
			Ui.slam(warn, 0.6, 2.4, 0.35, function()
			{
				Juice.shake(0.4);
				Audio.sfx("slam");
			});
			var sub = Ui.text(0, 372, G.W, "Hyperlane ahead. Don't touch the walls.", 18, G.WHITE);
			top.add(sub);
			Ui.fadeIn(sub, 0.9);
			new FlxTimer().start(0.4, function(_) Audio.sfx("alarm"));
		}
	}

	function clearTop():Void
	{
		for (m in top.members)
			if (m != null)
			{
				FlxTween.cancelTweensOf(m);
				m.destroy();
			}
		top.clear();
	}

	static function sentence(s:String):String
	{
		var l = s.toLowerCase();
		return l.charAt(0).toUpperCase() + l.substr(1);
	}

	function enterPrompt():Void
	{
		clearTop();
		var id = run.nextId();
		run.lastId = id;
		info = Catalog.get(id);
		micro = info.make(run.level(), run.speed());
		micro.attach(this);
		gameLayer.add(micro);

		bridge.visible = false;
		hudBridge.visible = false;
		hudPlay.visible = true;
		paintFuse(1);
		refreshHud();
		flash(0.25);
		kick(1.0);
		Audio.sfx("prompt");

		var text = splitVerb(info.verb);
		var longest = 0;
		for (l in text.split("\n"))
			longest = Std.int(Math.max(longest, l.length));
		var longestLine = "";
		for (l in text.split("\n"))
			if (l.length > longestLine.length)
				longestLine = l;
		var size = VecFont.fit(longestLine, 70, 400);
		prompt = Ui.stamp(text, size, G.ORANGE, G.W / 2, 420, true, Ui.tilt() * 0.6);
		top.add(prompt);
		Ui.slam(prompt, 0, 2.4, 0.26, function()
		{
			Audio.sfx("slam");
			Juice.shake(0.2);
			sparks.burst(G.W / 2, 420, G.ORANGE, 14, 420, 0.35, 0.4);
		});

		hint = Ui.text(0, 0, G.W, sentence(info.hint), 20, G.INK);
		hint.y = prompt.y + prompt.height + 26;
		hintBg = Art.label(Std.int(Math.max(170, hint.textWidth + 80)), 50, G.KRAFT);
		hintBg.x = G.W / 2 - (hintBg.width - 7) / 2;
		hintBg.y = hint.y + hint.height / 2 - (hintBg.height - 7) / 2;
		hint.x += 8;
		top.add(hintBg);
		top.add(hint);
		Ui.fadeIn(hintBg, 0.12, 0.25, 12);
		Ui.fadeIn(hint, 0.12, 0.25, 12);

		tagText = VecFont.sprite(info.verb, 21, G.INK, 0, 0);
		var tw = Std.int(tagText.width + 64);
		tag = Art.label(tw, 52, G.KRAFT);
		tag.setPosition(G.W / 2 - tw / 2 + 2, 16);
		tag.alpha = 0;
		tagText.setPosition(tag.x + 8 + (tag.width - 7) / 2 - tagText.width / 2, tag.y + (tag.height - 7) / 2 - tagText.height / 2);
		tagText.alpha = 0;
		hudPlay.add(tag);
		hudPlay.add(tagText);

		var len = Math.max(0.8, G.beat(run.speed()) * 2.2);
		if (run.isBoss())
			len += 0.4;
		setPhase(PROMPT, len);
	}

	static function splitVerb(v:String):String
	{
		if (v.length <= 10 || v.indexOf(" ") < 0)
			return v;
		var best = v;
		var bestW = 999;
		for (i in 0...v.length)
		{
			if (v.charAt(i) != " ")
				continue;
			var w = Std.int(Math.max(i, v.length - i - 1));
			if (w < bestW)
			{
				bestW = w;
				best = v.substr(0, i) + "\n" + v.substr(i + 1);
			}
		}
		return best;
	}

	function enterPlay():Void
	{
		setPhase(PLAY, 0);
		micro.start();
		lastTick = 99;
		FlxTween.tween(prompt, {alpha: 0, y: prompt.y - 40}, 0.18, {ease: FlxEase.quadIn});
		FlxTween.tween(hint, {alpha: 0}, 0.12);
		FlxTween.tween(hintBg, {alpha: 0}, 0.12);
		FlxTween.tween(tag, {alpha: 1}, 0.2);
		FlxTween.tween(tagText, {alpha: 1}, 0.2);
	}

	function enterResult():Void
	{
		var won = micro.won;
		var wasBoss = run.isBoss();
		var fuseLeft = micro.survive ? 0 : micro.timeLeft / micro.duration;
		lastGain = run.record(won, fuseLeft);
		lastWon = won;
		lastFast = won && fuseLeft > 0.45;
		setPhase(RESULT, micro.outro + (won ? 0 : 0.15));
		paintFuse(micro.timeLeft / micro.duration);
		var stamp:FlxSprite;
		if (won)
		{
			Audio.sfx("win");
			stamp = Ui.stamp(wasBoss ? "CLEARED" : "SIGNED", 54, G.STAMP_GREEN, G.W / 2, 470, true, Ui.tilt());
			Juice.medium(G.W / 2, 470, G.GREEN);
			if (lastFast)
			{
				var f = Ui.stamp("FAST", 30, G.YELLOW, G.W / 2 + 120, 540, true, 10);
				top.add(f);
				Ui.slam(f, 0.12, 2, 0.25, function() Audio.sfx("coin", 1.4));
			}
		}
		else
		{
			Audio.sfx("lose");
			stamp = Ui.stamp("DAMAGED", 56, G.STAMP_RED, G.W / 2, 470, true, Ui.tilt());
			Juice.large(G.W / 2, 470, G.RED);
			hurt();
			if (run.hasClock && !run.late)
			{
				var lateNow = run.spend(FAIL_PENALTY);
				var pen = Ui.text(G.W - 220, 850, 196, '-${Std.int(FAIL_PENALTY)}s', 24, G.RED, "right");
				top.add(pen);
				Ui.pop(cast pen, 0.5);
				FlxTween.tween(pen, {y: 820, alpha: 0}, 0.8, {startDelay: 0.3});
				if (lateNow)
					onLate();
			}
		}
		top.add(stamp);
		Ui.slam(stamp, 0, 2.2, 0.24);
		paintClock();
		refreshHud();
	}

	/** The guarantee just ran out: the delivery is free now, but the job goes on. */
	function onLate():Void
	{
		var s = Ui.stamp("LATE", 60, G.STAMP_RED, G.W / 2, 640, true, -12);
		top.add(s);
		Ui.slam(s, 0.25, 3, 0.35, function()
		{
			Audio.sfx("alarm");
			Juice.large(G.W / 2, 640, G.RED);
		});
	}

	function finishRound():Void
	{
		FlxTween.cancelTweensOf(micro);
		gameLayer.remove(micro, true);
		micro.destroy();
		micro = null;
		for (m in [tag, tagText])
		{
			hudPlay.remove(m, true);
			m.destroy();
		}

		if (run.lives <= 0)
		{
			setPhase(EXIT, 0);
			finishRun(false);
			return;
		}
		var sectorDone = run.advance();
		if (sectorDone)
		{
			sectorJustCleared = true;
			if (run.storyDone())
			{
				setPhase(EXIT, 0);
				finishRun(true);
				return;
			}
			if (run.mode == STORY)
			{
				setPhase(EXIT, 0);
				go(() -> new CutsceneState("sector" + run.sector));
				return;
			}
			lastWon = null;
			clearTop();
			enterCard();
			return;
		}
		enterBridge();
	}

	function finishRun(victory:Bool):Void
	{
		Audio.music("");
		if (run.mode == STORY)
			go(() -> new CutsceneState(victory ? "ending" : "gameover"));
		else
			go(() -> new ResultState(victory));
	}

	// ---------------------------------------------------------------- update

	override public function update(elapsed:Float):Void
	{
		if (phase != EXIT && (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.P || (Input.justPressed && overPause())))
		{
			pause();
			return;
		}
		super.update(elapsed);
		t += elapsed;
		run.time += elapsed;
		phaseT += elapsed;
		animateShip(elapsed);

		switch (phase)
		{
			case CARD:
				if (phaseT >= phaseLen)
				{
					clearTop();
					enterBridge();
				}
			case BRIDGE:
				if (phaseT >= phaseLen)
					enterPrompt();
			case PROMPT:
				if (phaseT >= phaseLen)
					enterPlay();
			case PLAY:
				var ratio = micro.timeLeft / micro.duration;
				paintFuse(ratio);
				tickClock(elapsed);
				var beatsLeft = Math.ceil(micro.timeLeft / G.beat(run.speed()));
				if (beatsLeft <= 3 && beatsLeft < lastTick && !micro.survive)
				{
					Audio.sfx("tick", beatsLeft == 1 ? 1.5 : 1);
					FlxTween.cancelTweensOf(fuseTrack.scale);
					fuseTrack.scale.set(1.03, 1.5);
					FlxTween.tween(fuseTrack.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.backOut});
				}
				lastTick = beatsLeft;
				if (micro.finished)
					enterResult();
			case RESULT:
				if (phaseT >= phaseLen)
					finishRound();
			case EXIT:
		}
	}

	function tickClock(elapsed:Float):Void
	{
		if (!run.hasClock || run.late)
			return;
		if (run.spend(elapsed))
			onLate();
		var sec = Std.int(run.guarantee);
		if (sec < 10 && sec != lastSecond)
		{
			Audio.sfx("beep", 1.4);
			if (playClock != null)
				Ui.pop(cast playClock, 0.3);
		}
		lastSecond = sec;
		paintClock();
	}

	function overPause():Bool
	{
		var m = FlxG.mouse;
		return m.x > pauseBtn.x - 10 && m.y < pauseBtn.y + pauseBtn.height + 10;
	}

	function pause():Void
	{
		Audio.sfx("click");
		var o:Overlay = null;
		o = new Overlay("Paused", [
			{label: () -> "RESUME", primary: true, action: function(_) o.dismiss()},
			{
				label: () -> "OPTIONS",
				action: function(_)
				{
					o.dismiss();
					new FlxTimer().start(0.01, function(_) openSubState(Overlay.options(this)));
				}
			},
			{
				label: () -> "QUIT TO MENU",
				action: function(_)
				{
					o.dismiss();
					phase = EXIT;
					Audio.music("");
					go(TitleState.new);
				}
			}
		], "The clock stops while you're paused.");
		openSubState(o);
	}

	function paintFuse(ratio:Float):Void
	{
		ratio = Math.max(0, Math.min(1, ratio));
		fuseFill.scale.x = Math.max(0.001, ratio);
		var col = ratio > 0.5 ? G.CYAN : (ratio > 0.25 ? G.YELLOW : G.RED);
		if (micro != null && micro.survive)
			col = G.GREEN;
		fuseFill.color = col;
		fuseSpark.color = col;
		fuseSpark.setPosition(fuseFill.x + 466 * ratio - fuseSpark.width / 2, 926 - fuseSpark.height / 2);
		var s = 1.2 + Math.random() * 0.6;
		fuseSpark.scale.set(s, s);
		if (phase == PLAY && FlxG.random.bool(50))
			sparks.puff(fuseFill.x + 466 * ratio, 926, col, FlxG.random.float(-60, 20), FlxG.random.float(-80, 10), 0.35, 0.3);
	}

	function animateShip(elapsed:Float):Void
	{
		if (!bridge.visible)
			return;
		shipKick = Math.max(0, shipKick - elapsed * 2.2);
		var bob = Math.sin(t * 2.4) * 10;
		var sway = Math.sin(t * 1.1) * 26;
		var x = G.W / 2 + sway;
		var y = 420 + bob - shipKick * shipKick * 70;
		if (phase == BRIDGE && lastWon == false && phaseT < 0.7)
		{
			x += Math.sin(t * 60) * 6 * (1 - phaseT / 0.7);
			if (FlxG.random.bool(40))
				sparks.puff(x + FlxG.random.float(-20, 20), y, 0xFF6A6478, FlxG.random.float(-40, 40), 160, 0.6, 0.6);
		}
		ship.x = x - ship.width / 2;
		ship.y = y - ship.height / 2;
		// Squash and stretch on the boost after a clear: tall and thin, settling back.
		var sq = shipKick * 0.18;
		ship.scale.set(1 - sq, 1 + sq);
		var power = 1.2 + (run.speed() - 1) * 0.6 + shipKick * 1.5;
		flame.x = x - flame.width / 2;
		flame.y = y + 38;
		var f = (0.85 + Math.random() * 0.3) * power;
		flame.scale.set(f, f * 1.2);
		if (FlxG.random.bool(70))
			sparks.puff(x + FlxG.random.float(-8, 8), y + 80, G.ORANGE, FlxG.random.float(-20, 20), 420, 0.6, 0.35);
	}
}
