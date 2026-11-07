package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import fx.Fx;
import minigames.Catalog;
import minigames.MiniGame;

class PlayState extends FlxState
{
	var world:FlxGroup;
	var game:MiniGame;
	var hearts:Array<FlxSprite> = [];
	var scoreText:FlxText;
	var rateText:FlxText;
	var promptText:FlxText;
	var timeFill:FlxSprite;
	var veil:FlxSprite;
	var banner:FlxText;
	var rewardText:FlxText;
	var fasterBg:FlxSprite;
	var waiting:Bool = false;
	var waitLeft:Float = 0;
	var celebrateFaster:Bool = false;

	override public function create():Void
	{
		Run.boot();
		Fx.mount(this, 1);

		world = new FlxGroup();
		add(world);

		veil = new FlxSprite();
		veil.makeGraphic(Run.W, Run.H, 0xAAFFFFFF);
		veil.visible = false;
		add(veil);

		var hud = new FlxGroup();
		add(hud);
		hud.add(Gfx.panel(0, 0, Run.W, 168, 0xB0060610));

		for (i in 0...Run.MAX_HEARTS)
		{
			var heart = Gfx.heart();
			heart.x = 22 + i * 42;
			heart.y = 22;
			hearts.push(heart);
			hud.add(heart);
		}
		paintHearts();

		rateText = Gfx.label(150, 22, 170, Run.gainLabel(), 22, 0xFFD6C48A);
		rateText.alignment = "right";
		hud.add(rateText);

		scoreText = Gfx.label(320, 14, 200, Run.iqText(Run.iq) + " IQ", 32, 0xFFE8F7FF);
		scoreText.alignment = "right";
		hud.add(scoreText);

		var ruleLabel = Gfx.label(20, 58, 500, "RULE", 16, 0xFF9BB4CC, false);
		hud.add(ruleLabel);
		promptText = Gfx.label(20, 80, 500, "", 30, 0xFFE8F7FF);
		hud.add(promptText);

		hud.add(Gfx.panel(40, 136, 460, 16, 0xFF12161E));
		timeFill = Gfx.panel(40, 136, 460, 16, 0xFFFFFFFF);
		timeFill.color = 0xFFD6E8F8;
		hud.add(timeFill);

		fasterBg = Gfx.panel(0, 0, Run.W, Run.H, 0xFFE7F1FA, false);
		fasterBg.visible = false;
		add(fasterBg);

		banner = Gfx.label(0, 390, Run.W, "", 72, 0xFFFFFFFF);
		banner.visible = false;
		add(banner);
		rewardText = Gfx.label(0, 500, Run.W, "", 48, 0xFF101820);
		rewardText.visible = false;
		add(rewardText);

		spawn();
		super.create();
	}

	function spawn():Void
	{
		game = Catalog.pick(Run.speed);
		world.add(game);
		promptText.text = game.prompt;
		banner.visible = false;
		rewardText.visible = false;
		fasterBg.visible = false;
		veil.visible = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (waiting)
		{
			waitLeft -= elapsed;
			if (waitLeft <= 0)
				advance();
			return;
		}

		if (game != null && game.done)
			finish();
		else if (game != null)
			paintTime();
	}

	function paintTime():Void
	{
		var ratio = game.duration <= 0 ? 0 : game.timeLeft / game.duration;
		Gfx.clipWidth(timeFill, 460, ratio);
		timeFill.color = ratio < 0.3 ? 0xFFE23B4A : 0xFFD6E8F8;
	}

	function finish():Void
	{
		waiting = true;
		waitLeft = Run.pauseTime();
		if (game.won)
		{
			var gain = Run.iqGain();
			Run.iq += gain;
			banner.text = Run.gainLabel(gain);
			veil.color = 0xFF3DDC97;
		}
		else
		{
			Run.hearts--;
			banner.text = "OUCH";
			veil.color = 0xFFE23B4A;
			paintHearts();
		}
		scoreText.text = Run.iqText(Run.iq) + " IQ";
		Run.advance();
		celebrateFaster = Run.hearts > 0 && Run.iq < Run.WIN_IQ && Run.round % Run.SET == 0;
		banner.color = 0xFFFFFFFF;
		banner.visible = true;
		veil.visible = true;
		Gfx.clipWidth(timeFill, 460, 0);
	}

	function paintHearts():Void
	{
		for (i in 0...hearts.length)
			hearts[i].color = i < Run.hearts ? 0xFFFFFFFF : 0xFF2A2438;
	}

	function advance():Void
	{
		waiting = false;
		banner.visible = false;
		veil.visible = false;
		if (Run.hearts <= 0)
		{
			Run.commitBest();
			FlxG.switchState(GameOverState.new);
			return;
		}
		if (Run.iq >= Run.WIN_IQ)
		{
			Run.commitBest();
			FlxG.switchState(WinState.new);
			return;
		}
		if (celebrateFaster)
		{
			celebrateFaster = false;
			showFaster();
			return;
		}
		banner.color = 0xFFFFFFFF;
		fasterBg.visible = false;
		world.remove(game, true);
		game.destroy();
		spawn();
	}

	function showFaster():Void
	{
		Run.bump();
		rateText.text = Run.gainLabel();
		fasterBg.visible = true;
		banner.text = "FASTER";
		banner.color = 0xFF101820;
		banner.visible = true;
		rewardText.text = Run.gainLabel();
		rewardText.color = 0xFF101820;
		rewardText.visible = true;
		veil.visible = false;
		waiting = true;
		waitLeft = 1.5;
	}
}
