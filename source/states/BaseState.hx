package states;

import core.Art;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.typeLimit.NextState;
import fx.PostShader;
import fx.Sparks;
import fx.Starfield;
import openfl.filters.ShaderFilter;

/** Shared scaffolding: warp backdrop, particles, post-processing and the slanted wipe transition. */
class BaseState extends FlxState
{
	public var stars:Starfield;
	public var sparks:Sparks;

	var post:PostShader;
	var wipe:FlxSprite;
	var veil:FlxSprite;
	var leaving:Bool = false;
	var aberr:Float = 0;
	var redTint:Float = 0;
	var clock:Float = 0;

	override public function create():Void
	{
		G.boot();
		FlxSprite.defaultAntialiasing = false;
		FlxG.camera.pixelPerfectRender = true;
		bgColor = 0xFF000000;
		FlxG.camera.bgColor = 0xFF000000;
		post = new PostShader();
		applyPost();

		stars = new Starfield();
		add(stars);
		sparks = new Sparks();

		build();

		veil = new FlxSprite().makeGraphic(G.W, G.H, 0xFFFFFFFF);
		veil.scrollFactor.set(0, 0);
		veil.alpha = 0;
		add(veil);

		wipe = makeWipe();
		add(wipe);
		wipe.y = -240;
		FlxTween.tween(wipe, {y: -G.H - 620}, 0.45, {ease: FlxEase.quartInOut});
		super.create();
	}

	public function applyPost():Void
	{
		// Always on: the pixel grid is the art style. Screen FX only gates flashes and aberration.
		FlxG.camera.filters = [new ShaderFilter(post)];
	}

	function build():Void {}

	/** The transition is the HyperDash livery: an ink panel led by orange and hazard stripes. */
	static function makeWipe():FlxSprite
	{
		var s = Art.sprite("wipe", G.W, G.H + 480, function(g)
		{
			g.lineStyle();
			Art.fill(g, 0x16111F);
			Art.poly(g, [0, 240, G.W, 0, G.W, G.H + 240, 0, G.H + 480]);
			g.endFill();
			Art.fill(g, 0xFF5B1F);
			Art.poly(g, [0, 240, G.W, 0, G.W, 44, 0, 284]);
			g.endFill();
			Art.fill(g, 0xFFC21A);
			Art.poly(g, [0, 296, G.W, 56, G.W, 70, 0, 310]);
			Art.poly(g, [0, G.H + 466, G.W, G.H + 226, G.W, G.H + 240, 0, G.H + 480]);
			g.endFill();
		}, 0);
		s.x = (G.W - s.width) / 2;
		s.scrollFactor.set(0, 0);
		return s;
	}

	/** Wipes the screen, then switches. */
	public function go(next:NextState):Void
	{
		if (leaving)
			return;
		leaving = true;
		members.remove(wipe);
		members.push(wipe);
		wipe.y = G.H;
		FlxTween.tween(wipe, {y: -240}, 0.4, {
			ease: FlxEase.quartInOut,
			onComplete: function(_) FlxG.switchState(next)
		});
	}

	/** Chromatic punch, e.g. on impacts. */
	public function kick(amount:Float = 1):Void
	{
		aberr = Math.max(aberr, amount);
	}

	public function hurt():Void
	{
		redTint = 0.6;
		kick(1.6);
	}

	/** Brief white flash for large impacts. Skipped when screen effects are off. */
	public function flash(amount:Float = 0.4):Void
	{
		if (!G.screenFx)
			return;
		members.remove(veil);
		members.insert(members.indexOf(wipe), veil);
		veil.alpha = Math.max(veil.alpha, amount);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		clock += elapsed;
		aberr = Math.max(0, aberr - elapsed * 3);
		redTint = Math.max(0, redTint - elapsed * 1.5);
		veil.alpha = Math.max(0, veil.alpha - elapsed * 4);
		post.uTime.value = [clock];
		post.uAberr.value = [G.screenFx ? aberr : 0];
		post.uTintR.value = [redTint];
	}
}
