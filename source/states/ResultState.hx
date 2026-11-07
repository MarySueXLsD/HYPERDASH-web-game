package states;

import core.Art;
import core.Audio;
import core.G;
import core.Juice;
import core.Run;
import core.Ui;
import core.VecFont;
import flixel.FlxG;
import flixel.FlxSprite;
import core.PixelText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

/** End of a run, printed as a delivery receipt that rolls out of the dash, then stamped. */
class ResultState extends BaseState
{
	static inline var SLIP_W:Int = 440;
	static inline var INK2:Int = 0xFF5A5468;

	var victory:Bool;
	var run:Run;
	var tipsText:PixelText;
	var shownScore:Float = 0;
	var counting:Bool = false;
	var slipX:Float;

	public function new(victory:Bool)
	{
		super();
		this.victory = victory;
	}

	override function build():Void
	{
		run = G.run;
		if (run == null)
			run = new Run(STORY);
		Audio.music(victory ? "win" : "over");
		Audio.setTempo(1);
		stars.rate = victory ? 0.5 : 0.08;
		stars.stretch = victory ? 0.3 : 0.02;

		// Story bonus: unspent guarantee time is paid out as tips.
		var bonus = 0;
		if (run.mode == STORY && victory && !run.late)
		{
			bonus = Std.int(run.guarantee * 50);
			run.score += bonus;
		}

		slipX = (G.W - SLIP_W) / 2;
		var slip = Art.receipt(SLIP_W, 700);
		slip.setPosition(slipX, 70);
		add(slip);
		var parts:Array<FlxSprite> = [slip];

		var head = VecFont.sprite("HYPERDASH", 30, G.ORANGE, 0.22, 0, 6);
		head.setPosition(slipX + 36, 110);
		add(head);
		parts.push(head);
		var mode = switch (run.mode)
		{
			case STORY: "Delivery receipt";
			case ENDLESS: "Shift report";
			case TRAINING: "Practice slip";
		}
		parts.push(line(150, mode, "", 16));
		parts.push(rule(186));

		var rows:Array<Array<String>> = [
			["Jobs done", run.cleared + " of " + run.played],
			["Best streak", Std.string(run.bestStreak)],
			["Top warp", G.fixed(run.topSpeed)],
			["Air time", G.clock(run.time).substr(0, -3)]
		];
		if (run.mode == STORY)
			rows.push(["Guarantee", !victory ? "lost" : (run.late ? "missed" : G.clock(run.guarantee).substr(0, -3) + " left")]);
		if (run.mode == STORY)
			rows.unshift(["Pilot", core.Pilots.get(run.pilot).name]);
		if (bonus > 0)
			rows.push(["Early tip", "+" + G.thousands(bonus)]);
		var y = 204.0;
		for (r in rows)
		{
			parts.push(line(y, r[0], r[1], 18));
			y += 38;
		}
		parts.push(rule(y + 6));
		var tl = Ui.text(slipX + 36, y + 26, 200, "Tips", 22, G.INK, "left");
		add(tl);
		parts.push(tl);
		tipsText = Ui.text(slipX + 160, y + 18, SLIP_W - 196, "0 cr", 34, G.INK, "right");
		add(tipsText);
		parts.push(tipsText);

		var bars = barcode(run.score + run.played * 7919);
		bars.setPosition(slipX + 36, 640);
		add(bars);
		parts.push(bars);

		var key = run.scoreKey();
		var prev = G.best(key);
		var record = G.submit(key, run.score) && run.score > 0;
		var bl = Ui.text(slipX + 36, 700, SLIP_W - 180, record ? "New best!" : "Best: " + G.thousands(prev) + " cr", 16, record ? G.STAMP_RED : INK2, "left");
		add(bl);
		parts.push(bl);

		// Print the receipt: everything slides up out of the bottom of the screen.
		for (p in parts)
		{
			var ty = p.y;
			p.y += G.H;
			FlxTween.tween(p, {y: ty}, 0.8, {ease: FlxEase.quartOut, startDelay: 0.15});
		}
		new FlxTimer().start(0.15, function(_) Audio.sfx("swipe"));

		var word = switch (run.mode)
		{
			case STORY: victory ? (run.late ? "LATE" : "DELIVERED") : "LOST";
			case ENDLESS: "SHIFT OVER";
			case TRAINING: "PRACTICED";
		}
		var col = (victory && !run.late) || run.mode == TRAINING ? G.STAMP_GREEN : G.STAMP_RED;
		if (run.mode == ENDLESS)
			col = G.ORANGE;
		var stampY = (y + 64 + 636) / 2;
		var stamp = Ui.stamp(word, VecFont.fit(word, 49, 380), col, G.W / 2, stampY, true, -14);
		add(stamp);
		Ui.slam(stamp, 1.1, 2.6, 0.35, function()
		{
			Audio.sfx("slam");
			Juice.medium(G.W / 2, stampY, col);
		});

		var rank = run.rank();
		if (rank != "")
		{
			var rc = switch (rank)
			{
				case "S", "A": G.STAMP_GREEN;
				case "B": G.ORANGE;
				default: G.STAMP_RED;
			}
			var rs = Ui.stamp(rank, 54, rc, slipX + SLIP_W - 86, 690, true, 9);
			add(rs);
			Ui.slam(rs, 1.9, 3, 0.35, function()
			{
				Audio.sfx(rank == "F" ? "denied" : "slam");
				if (rank == "F")
					Juice.medium(rs.x + rs.width / 2, 690, rc);
				else
					Juice.large(rs.x + rs.width / 2, 690, rc);
			});
		}

		add(sparks);

		// The story is a relay: losing hands the parcel to the next pilot.
		var again = "FLY AGAIN";
		if (run.mode == STORY)
		{
			var lastPilot = run.pilot >= core.Pilots.ALL.length - 1;
			if (victory || lastPilot)
				core.Pilots.setCurrent(0);
			else
				core.Pilots.setCurrent(run.pilot + 1);
			if (!victory)
				again = lastPilot ? "START OVER" : "NEXT PILOT";
		}
		var retry = new Button(G.W / 2 - 260, 812, 256, 72, again, true, retryRun, 22);
		var menu = new Button(G.W / 2 + 4, 812, 256, 72, "MENU", false, function() go(TitleState.new), 22);
		add(retry);
		add(menu);
		Ui.fadeIn(retry, 1.5, 0.4, 40);
		Ui.fadeIn(menu, 1.6, 0.4, 40);
		add(new Nav([retry, menu], 2));

		new FlxTimer().start(1.0, function(_) counting = true);
		if (victory && !run.late)
			new FlxTimer().start(0.5, function(_) celebrate(), 6);
	}

	function line(y:Float, left:String, right:String, size:Int):PixelText
	{
		var a = Ui.text(slipX + 36, y, SLIP_W - 72, left, size, INK2, "left");
		add(a);
		if (right != "")
		{
			var b = Ui.text(slipX + 36, y, SLIP_W - 72, right, size, G.INK, "right");
			add(b);
			var ty = b.y;
			b.y += G.H;
			FlxTween.tween(b, {y: ty}, 0.8, {ease: FlxEase.quartOut, startDelay: 0.15});
		}
		return a;
	}

	function rule(y:Float):FlxSprite
	{
		var r = Art.sprite("receiptrule", SLIP_W - 72, 4, function(g)
		{
			g.lineStyle();
			Art.fill(g, G.INK, 0.5);
			var x = 0.0;
			while (x < SLIP_W - 72)
			{
				g.drawRect(x, 1, 6, 2);
				x += 10;
			}
			g.endFill();
		}, 0);
		r.setPosition(slipX + 36, y);
		add(r);
		return r;
	}

	static function barcode(seed:Int):FlxSprite
	{
		return Art.sprite("barcode" + seed, 220, 44, function(g)
		{
			var rnd = new flixel.math.FlxRandom(seed);
			g.lineStyle();
			Art.fill(g, G.INK);
			var x = 0.0;
			while (x < 216)
			{
				var w = rnd.int(1, 4);
				g.drawRect(x, 0, w, 44);
				x += w + rnd.int(1, 4);
			}
			g.endFill();
		}, 0);
	}

	function celebrate():Void
	{
		var x = FlxG.random.float(60, G.W - 60);
		var y = FlxG.random.float(60, 300);
		var c = FlxG.random.getObject([G.ORANGE, G.YELLOW, G.GREEN, G.CYAN]);
		sparks.burst(x, y, c, 30, 420, 0.9, 0.7);
		sparks.shock(x, y, c, 1);
		Audio.sfx("pop", FlxG.random.float(0.8, 1.4));
	}

	function retryRun():Void
	{
		G.run = new Run(run.mode, run.trainingId);
		if (run.mode == STORY)
			go(() -> new CutsceneState("intro"));
		else
			go(RunState.new);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (counting && shownScore < run.score)
		{
			var step = Math.max(1, run.score * elapsed / 1.1);
			shownScore = Math.min(run.score, shownScore + step);
			tipsText.text = G.thousands(Std.int(shownScore)) + " cr";
			if (Std.int(shownScore / 80) != Std.int((shownScore - step) / 80))
				Audio.sfx("tick", 0.8 + shownScore / Math.max(1, run.score) * 0.6);
			if (shownScore >= run.score)
				Ui.pop(cast tipsText, 0.3);
		}
	}
}
