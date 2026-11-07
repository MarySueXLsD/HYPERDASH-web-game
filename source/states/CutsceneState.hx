package states;

import core.Input;
import core.Art;
import core.PixelFont;
import core.Audio;
import core.G;
import core.Ui;
import core.VecFont;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import core.PixelText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.Story.Cmd;

/** Plays a scripted scene: letterboxed stage, ship choreography and typed dialogue with portraits. */
class CutsceneState extends BaseState
{
	static inline var CPS:Float = 52;

	var id:String;
	var script:Array<Cmd>;
	var index:Int = -1;
	var waiting:Float = 0;
	var blocking:Bool = false;

	var stage:FlxGroup;
	var props:FlxGroup;
	var ship:FlxSprite;
	var flame:FlxSprite;
	var shipY:Float = 520;
	var shipMode:String = "hidden";
	var shake:Float = 0;
	var t:Float = 0;

	var barTop:FlxSprite;
	var barBottom:FlxSprite;
	var box:FlxSprite;
	var nameTag:FlxSprite;
	var nameTab:FlxSprite;
	var portrait:FlxSprite;
	var portraitTalk:FlxSprite;
	var line:PixelText;
	var more:FlxSprite;
	var speaker:String;
	var fullText:String = "";
	var shown:Float = 0;
	var typing:Bool = false;
	var dialog:FlxGroup;
	var card:FlxGroup;
	var skip:Button;
	var done:Bool = false;

	public function new(id:String)
	{
		super();
		this.id = id;
	}

	override function build():Void
	{
		script = Story.script(id);
		stage = new FlxGroup();
		add(stage);
		props = new FlxGroup();
		add(sparks);
		flame = Art.flame();
		add(flame);
		ship = core.Pilots.ship(core.Pilots.get(G.run != null ? G.run.pilot : 0));
		add(ship);
		ship.visible = flame.visible = false;
		add(props);

		barTop = new FlxSprite().makeGraphic(G.W, 96, 0xFF000000);
		barBottom = new FlxSprite().makeGraphic(G.W, 96, 0xFF000000);
		barTop.y = -96;
		barBottom.y = G.H;
		add(barTop);
		add(barBottom);
		FlxTween.tween(barTop, {y: 0}, 0.6, {ease: FlxEase.quartOut});
		FlxTween.tween(barBottom, {y: G.H - 96}, 0.6, {ease: FlxEase.quartOut});

		dialog = new FlxGroup();
		add(dialog);
		box = Art.receipt(G.W - 24, 208);
		box.setPosition(12, G.H - 96 - 216);
		dialog.add(box);
		portrait = new FlxSprite();
		portraitTalk = new FlxSprite();
		dialog.add(portrait);
		dialog.add(portraitTalk);

		more = VecFont.sprite(">", 16, G.ORANGE, 0, 0, 4);
		more.angle = 90;
		dialog.add(more);
		dialog.visible = false;

		card = new FlxGroup();
		add(card);

		skip = new Button(G.W - 140, 20, 124, 54, "SKIP", false, finish, 18);
		add(skip);

		next();
	}

	// ------------------------------------------------------------- commands

	function next():Void
	{
		if (done)
			return;
		index++;
		if (index >= script.length)
		{
			finish();
			return;
		}
		blocking = false;
		waiting = 0;
		run(script[index]);
		if (!blocking)
			next();
	}

	function run(c:Cmd):Void
	{
		switch (c)
		{
			case Music(name):
				Audio.music(name);
				Audio.setTempo(1);
			case Scene(piece, sector):
				var s = G.sector(sector);
				stars.tint(s.tintA, s.tintB, true);
				stars.center(G.W / 2, 400);
				buildScene(piece);
			case Warp(s):
				stars.stretch = s;
				stars.rate = 0.15 + s * 2.4;
			case Wait(time):
				blocking = true;
				waiting = time;
			case Flash:
				stars.flash = 1;
				kick(1);
			case Sfx(name):
				Audio.sfx(name);
			case ShipIn:
				ship.visible = flame.visible = true;
				shipMode = "idle";
				shipY = G.H + 120;
				FlxTween.tween(this, {shipY: 330}, 1.2, {ease: FlxEase.quartOut});
				blocking = true;
				waiting = 0.7;
			case ShipOut:
				shipMode = "out";
				Audio.sfx("warp");
				FlxTween.tween(this, {shipY: -300}, 0.9, {ease: FlxEase.quartIn});
				new flixel.util.FlxTimer().start(0.55, function(_)
				{
					stars.flash = 0.9;
					kick(2);
				});
				hideDialog();
				blocking = true;
				waiting = 1.0;
			case ShipShake:
				shake = 1.2;
				core.Juice.large(G.W / 2, shipY, G.RED);
				hurt();
			case Prop(name):
				var p = name == "duck" ? Art.duck() : Art.parcel();
				Art.center(p, G.W / 2 + (name == "duck" ? 0 : 0), 330);
				props.forEach(function(o) cast(o, FlxSprite).visible = false);
				props.add(p);
				Ui.slam(p, 0, 0.2, 0.5);
				core.Juice.medium(G.W / 2, 330, G.YELLOW);
				FlxTween.tween(p, {y: p.y - 12}, 1.2, {type: PINGPONG, ease: FlxEase.sineInOut, startDelay: 0.5});
			case Card(kicker, title, sub):
				showCard(kicker, title, sub);
				blocking = true;
				waiting = 3.2;
			case Say(who, text):
				say(who, text);
				blocking = true;
				waiting = -1;
		}
	}

	function buildScene(piece:String):Void
	{
		stage.forEach(function(b) b.destroy());
		stage.clear();
		switch (piece)
		{
			case "station":
				var s = Art.station();
				Art.center(s, G.W / 2, 290);
				stage.add(s);
				FlxTween.tween(s, {y: s.y + 10}, 3, {type: PINGPONG, ease: FlxEase.sineInOut});
			case "rocks":
				for (i in 0...9)
				{
					var r = Art.rock(i, FlxG.random.float(24, 60));
					Art.center(r, FlxG.random.float(30, G.W - 30), FlxG.random.float(140, 760));
					var depth = FlxG.random.float(0.5, 1.2);
					r.scale.set(depth, depth);
					r.alpha = 0.4 + depth * 0.5;
					r.angularVelocity = FlxG.random.float(-30, 30);
					r.velocity.set(FlxG.random.float(-12, 12), 12 * depth);
					stage.add(r);
				}
			case "pirates":
				for (i in 0...3)
				{
					var p = Art.pirate();
					var x = G.W / 2 + (i - 1) * 160;
					var y = i == 1 ? 230 : 190;
					Art.center(p, x, -100);
					if (i != 1)
						p.scale.set(0.8, 0.8);
					stage.add(p);
					FlxTween.tween(p, {y: y - p.height / 2}, 1.4, {ease: FlxEase.backOut, startDelay: 0.6 + i * 0.15});
				}
			case "customs":
				var c = Art.customsGate();
				Art.center(c, G.W / 2, 280);
				stage.add(c);
				FlxTween.tween(c, {y: c.y + 8}, 3, {type: PINGPONG, ease: FlxEase.sineInOut});
			case "hole":
				var h = Art.blackHole();
				Art.center(h, G.W / 2, 290);
				stage.add(h);
				FlxTween.tween(h, {y: h.y + 8}, 3, {type: PINGPONG, ease: FlxEase.sineInOut});
			case "wreck":
				// The last pilot's ship, dark and tumbling, with debris around it.
				var prev = core.Pilots.get(Std.int(Math.max(0, (G.run != null ? G.run.pilot : 1) - 1)));
				var w = core.Pilots.ship(prev);
				w.color = 0xFF6A6478;
				Art.center(w, G.W / 2 + 120, 230);
				w.angularVelocity = 14;
				w.velocity.set(-6, 4);
				stage.add(w);
				for (i in 0...7)
				{
					var r = Art.rock(i + 20, FlxG.random.float(10, 26));
					r.color = 0xFF8A8098;
					Art.center(r, FlxG.random.float(40, G.W - 40), FlxG.random.float(140, 560));
					r.angularVelocity = FlxG.random.float(-60, 60);
					r.velocity.set(FlxG.random.float(-10, 10), FlxG.random.float(-6, 10));
					stage.add(r);
				}
			case "planet":
				var p = Art.planet();
				Art.center(p, G.W / 2, G.H + 200);
				stage.add(p);
				FlxTween.tween(p, {y: p.y - 360}, 3.5, {ease: FlxEase.quartOut});
			default:
		}
	}

	/** Title cards are route tickets that slide in and get stamped. */
	function showCard(kicker:String, title:String, ?sub:String):Void
	{
		hideDialog();
		var tk = Art.ticket(476, 380);
		Art.center(tk, G.W / 2, 400);
		card.add(tk);
		var k = Ui.text(tk.x + 32, tk.y + 34, 400, kicker, 18, 0xFF5A5468, "left");
		card.add(k);
		var longest = "";
		for (l in title.split("\n"))
			if (l.length > longest.length)
				longest = l;
		var size = VecFont.fit(longest, 49, 400);
		var tt = VecFont.sprite(title, size, G.INK, 0.14, 0, size * 0.17);
		tt.setPosition(tk.x + 32, k.y + k.height + 8);
		card.add(tt);
		if (sub != null)
		{
			var st = Ui.text(tk.x + 32, tt.y + tt.height + 12, 410, sub, 18, 0xFF5A5468, "left");
			card.add(st);
		}
		for (m in card.members)
		{
			var spr:FlxSprite = cast m;
			var tx = spr.x;
			spr.x += G.W;
			FlxTween.tween(spr, {x: tx}, 0.5, {ease: FlxEase.backOut});
		}
		new flixel.util.FlxTimer().start(0.35, function(_)
		{
			Audio.sfx("slam");
			core.Juice.shake(0.25);
		});
	}

	function clearCard():Void
	{
		card.forEach(function(b) b.destroy());
		card.clear();
	}

	function say(who:String, text:String):Void
	{
		clearCard();
		var first = !dialog.visible;
		dialog.visible = true;
		var color = Art.speakerColor(who);
		layoutBox(text);
		portrait.loadGraphic(Art.portrait(who, false).graphic);
		portraitTalk.loadGraphic(Art.portrait(who, true).graphic);
		portrait.setPosition(box.x + 26, box.y + 30);
		portraitTalk.setPosition(portrait.x, portrait.y);
		if (nameTag != null)
		{
			dialog.remove(nameTag, true);
			nameTag.destroy();
		}
		if (nameTab != null)
		{
			dialog.remove(nameTab, true);
			nameTab.destroy();
		}
		nameTab = Art.label(Std.int(VecFont.measure(who, 21) + 64), 46, color);
		nameTab.setPosition(box.x + 184, box.y + 44);
		dialog.add(nameTab);
		nameTag = VecFont.sprite(who, 21, G.INK, 0, 0);
		nameTag.setPosition(nameTab.x + 8 + (nameTab.width - 7) / 2 - nameTag.width / 2, nameTab.y + (nameTab.height - 7) / 2 - nameTag.height / 2);
		dialog.add(nameTag);
		fullText = text;
		shown = 0;
		typing = true;
		line.visibleChars = 0;
		speaker = who;
		if (first)
		{
			for (m in [box, portrait, portraitTalk, line, nameTab, nameTag])
				Ui.fadeIn(m, 0, 0.3, 30);
		}
		else
		{
			portrait.scale.set(1.08, 1.08);
			FlxTween.tween(portrait.scale, {x: 1, y: 1}, 0.2);
		}
	}

	/**
	 * Sizes the slip to the line being spoken. Short lines sit beside the
	 * portrait under the name tag; longer ones run full width underneath it.
	 * The slip stays anchored to the bottom letterbox bar.
	 */
	function layoutBox(text:String):Void
	{
		var bottom = G.H - 96 - 8;
		var sideX = 184.0;
		var sideW = box.width - sideX - 30;
		var side = PixelFont.measure(text, 3, sideW);
		var beside = side.lines.length <= 3;
		var tx:Float, ty:Float, tw:Float, th:Float;
		if (beside)
		{
			tx = sideX;
			ty = 102;
			tw = sideW;
			th = side.h;
		}
		else
		{
			tx = 30;
			ty = 184;
			tw = box.width - 60;
			th = PixelFont.measure(text, 3, tw).h;
		}
		var h = Std.int(Math.max(208, ty + th + 44));
		h = Std.int(Math.ceil(h / 16) * 16);
		box.loadGraphic(Art.receipt(Std.int(box.width), h).graphic);
		box.y = bottom - h;
		if (line != null)
		{
			dialog.remove(line, true);
			line.destroy();
		}
		line = Ui.text(box.x + tx, box.y + ty, tw, text, 20, G.INK, "left");
		dialog.add(line);
	}

	function hideDialog():Void
	{
		if (!dialog.visible)
			return;
		dialog.visible = false;
	}

	function finish():Void
	{
		if (done)
			return;
		done = true;
		var r = G.run;
		switch (id)
		{
			case "ending":
				G.setFlag("story");
				go(() -> new ResultState(true));
			case "gameover":
				go(() -> new ResultState(false));
			default:
				go(RunState.new);
		}
	}

	// ---------------------------------------------------------------- update

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		t += elapsed;
		animateShip(elapsed);

		if (dialog.visible)
		{
			if (typing)
			{
				var before = Std.int(shown);
				shown += elapsed * CPS;
				var n = Std.int(Math.min(fullText.length, shown));
				if (n != before)
				{
					line.visibleChars = n;
					var ch = fullText.charAt(n - 1);
					if (n % 2 == 0 && ch != " ")
						Audio.sfx("type");
				}
				if (n >= fullText.length)
					typing = false;
			}
			var talking = typing && Std.int(t * 10) % 2 == 0;
			portraitTalk.visible = talking;
			portrait.visible = !talking;
			more.visible = !typing && Std.int(t * 3) % 2 == 0;
			more.setPosition(box.x + box.width - 40, box.y + box.height - 36 + Math.sin(t * 6) * 3);
		}

		var tap = Input.justPressed || FlxG.keys.anyJustPressed([SPACE, ENTER, Z, X]);
		if (tap && Input.justPressed && FlxG.mouse.y < 96)
			tap = false;

		if (blocking && !done)
		{
			if (waiting >= 0)
			{
				waiting -= elapsed;
				if (waiting <= 0 || (tap && waitingIsCard()))
					next();
			}
			else if (tap)
			{
				if (typing)
				{
					typing = false;
					shown = fullText.length;
					line.visibleChars = -1;
				}
				else
				{
					Audio.sfx("click", 1.2);
					next();
				}
			}
		}
	}

	function waitingIsCard():Bool
	{
		return switch (script[index])
		{
			case Card(_, _, _): true;
			default: false;
		}
	}

	function animateShip(elapsed:Float):Void
	{
		if (!ship.visible)
			return;
		shake = Math.max(0, shake - elapsed);
		var bob = Math.sin(t * 2) * 8;
		var x = G.W / 2 + Math.sin(t * 0.8) * 14 + (shake > 0 ? FlxG.random.float(-8, 8) * shake : 0);
		var y = shipY + bob;
		ship.x = x - ship.width / 2;
		ship.y = y - ship.height / 2;

		var out = shipMode == "out";
		var power = id == "gameover" ? 0.3 : (out ? 2.4 : 1);
		flame.x = x - flame.width / 2;
		flame.y = y + 56;

		var f = (0.85 + Math.random() * 0.3) * power;
		flame.scale.set(f * 1.2, f * 1.5);
		flame.visible = id != "gameover" || FlxG.random.bool(30);
		if (FlxG.random.bool(out ? 100 : 60))
			sparks.puff(x + FlxG.random.float(-8, 8), y + 90, G.ORANGE, FlxG.random.float(-20, 20), 380, out ? 0.9 : 0.5, 0.4);
		if (id == "gameover" && FlxG.random.bool(30))
			sparks.puff(x + FlxG.random.float(-30, 30), y, 0xFF6A6A7A, FlxG.random.float(-30, 30), -90, 0.9, 0.9);
	}
}
