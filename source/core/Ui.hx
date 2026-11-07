package core;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Ui
{
	/**
	 * Body text in the hand-made pixel font. Small sizes use 2 px font pixels,
	 * larger ones 4 px, so every glyph stays on the art grid. Light text gets a
	 * crisp drop shadow; dark text (on paper) doesn't.
	 */
	public static function text(x:Float, y:Float, w:Float, str:String, size:Int, color:Int = 0xFFF2F2F5, align:String = "center"):PixelText
	{
		var px = size <= 22 ? 3 : 4;
		var c = flixel.util.FlxColor.fromInt(color);
		var light = c.lightness > 0.45;
		return new PixelText(Math.round(x), Math.round(y), w, str, px, color, align, light);
	}

	/** Stencil heading, centred on (x, y). UI never glows. */
	public static function title(str:String, size:Float, color:Int, x:Float, y:Float, slant:Float = 0.18, glow:Float = 0):FlxSprite
	{
		var s = VecFont.sprite(str, size, color, slant, glow);
		return Art.center(s, x, y);
	}

	/** Distressed rubber stamp centred on (x, y). */
	public static function stamp(str:String, size:Float, color:Int, x:Float, y:Float, framed:Bool = true, rot:Float = 0, stencil:Bool = false):FlxSprite
	{
		return Art.center(Art.stamp(str, size, color, framed, rot, stencil), x, y);
	}

	/** A slight random tilt for a stamp, from a small set so the baked graphics stay cached. */
	public static function tilt():Float
	{
		return FlxG.random.getObject([-8.0, -5.0, 5.0, 8.0]);
	}

	/**
	 * Stamp-style entrance: drops in from a larger scale, squashes on impact
	 * and springs back with overshoot.
	 */
	public static function slam(s:FlxSprite, delay:Float = 0, from:Float = 2.2, dur:Float = 0.35, ?onHit:Void->Void):Void
	{
		s.scale.set(from, from);
		s.alpha = 0;
		FlxTween.tween(s, {alpha: 1}, dur * 0.4, {startDelay: delay});
		FlxTween.tween(s.scale, {x: 1, y: 1}, dur * 0.55, {
			startDelay: delay,
			ease: FlxEase.quadIn,
			onComplete: function(_)
			{
				s.scale.set(1.22, 0.8);
				FlxTween.tween(s.scale, {x: 1, y: 1}, dur * 0.8, {ease: FlxEase.elasticOut});
				if (onHit != null)
					onHit();
			}
		});
	}

	/** Quick squash-and-stretch pulse for a value that just changed. */
	public static function pop(s:FlxSprite, amount:Float = 0.25):Void
	{
		FlxTween.cancelTweensOf(s.scale);
		s.scale.set(1 + amount, 1 - amount * 0.6);
		FlxTween.tween(s.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});
	}

	public static function fadeIn(s:FlxSprite, delay:Float = 0, dur:Float = 0.4, dy:Float = 20):Void
	{
		s.alpha = 0;
		var y = s.y;
		s.y += dy;
		FlxTween.tween(s, {alpha: 1, y: y}, dur, {startDelay: delay, ease: FlxEase.quartOut});
	}
}

/** Shipping-label button: press squashes it into its shadow, release springs it back. */
class Button extends FlxSpriteGroup
{
	public var onClick:Void->Void;
	public var enabled:Bool = true;
	public var focused(default, set):Bool = false;

	/** Set by a Nav so hovering with the mouse moves keyboard focus too. */
	public var onHover:Button->Void;

	var bg:FlxSprite;
	var label:FlxSprite;
	var focusBox:FlxSprite;
	var down:Bool = false;
	var hover:Bool = false;
	var flash:Float = 0;
	var ink:Int;
	var bw:Int;
	var bh:Int;
	var labelX:Float = 0;
	var labelY:Float = 0;

	/** `primary` buttons are safety orange; the rest are kraft. */
	public function new(x:Float, y:Float, w:Int, h:Int, caption:String, primary:Bool, onClick:Void->Void, size:Float = 26)
	{
		super(Std.int(x / Art.PX) * Art.PX, Std.int(y / Art.PX) * Art.PX);
		this.onClick = onClick;
		bw = w;
		bh = h;
		ink = G.INK;
		focusBox = Art.focusFrame(w + 4, h + 4);
		focusBox.setPosition(-6, -6);
		focusBox.visible = false;
		add(focusBox);
		bg = Art.label(w, h, primary ? G.ORANGE : G.KRAFT);
		add(bg);
		setCaption(caption, size);
	}

	static inline function grid(v:Float):Float
	{
		return Math.round(v / Art.PX) * Art.PX;
	}

	public function setCaption(caption:String, size:Float = 26):Void
	{
		if (label != null)
		{
			remove(label, true);
			label.destroy();
		}
		// Shrink long captions so they always fit inside the label, clear of the tag hole.
		var longest = 0;
		for (l in caption.split("\n"))
			longest = Std.int(Math.max(longest, l.length));
		size = Math.min(size, (bw - 56) * 6 / ((longest - 1) * 5.4 + 4 + 2));
		label = VecFont.sprite(caption, size, ink, 0, 0);
		while (label.width > bw - 30 && size > 14)
		{
			label.destroy();
			size -= 7;
			label = VecFont.sprite(caption, size, ink, 0, 0);
		}
		labelX = grid(bw / 2 + 8 - label.width / 2);
		labelY = grid(bh / 2 - 2 - label.height / 2);
		// FlxSpriteGroup.add offsets children by the group position, so place relative to it.
		label.x = labelX;
		label.y = labelY;
		add(label);
	}

	function set_focused(v:Bool):Bool
	{
		focused = v;
		if (focusBox != null)
			focusBox.visible = v;
		return v;
	}

	/** Activates the button as if clicked (keyboard / gamepad confirm). */
	public function press():Void
	{
		if (!enabled)
			return;
		Audio.unlock();
		Audio.sfx("click");
		flash = 0.1;
		if (onClick != null)
			onClick();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!enabled || !visible || alpha < 0.5)
			return;
		var px = FlxG.mouse.x;
		var py = FlxG.mouse.y;
		var over = px >= x && px <= x + bw && py >= y && py <= y + bh;
		if (over && !hover)
		{
			Audio.sfx("hover");
			if (onHover != null)
				onHover(this);
		}
		hover = over;
		if (Input.justPressed && over)
			down = true;
		if (Input.justReleased)
		{
			if (down && over)
				press();
			down = false;
		}
		// Motion is whole art pixels only: lift on hover/focus, sink into the shadow on press.
		// The focus frame moves with the label so the two never disagree.
		var off = down ? Art.PX * 2 : ((hover || focused) ? -Art.PX : 0);
		bg.x = x;
		bg.y = y + off;
		label.x = x + labelX;
		label.y = y + labelY + off;
		focusBox.x = x - 6;
		focusBox.y = y - 6 + off;
		flash = Math.max(0, flash - elapsed);
		bg.color = flash > 0 ? 0xFFFFFFFF : ((hover || focused) ? 0xFFFFFFFF : 0xFFE6DCCB);
	}
}

/**
 * Focus navigation over a set of buttons laid out in a grid. Arrow keys or
 * WASD move, Enter / Space / Z confirm. Something is always focused, and
 * mouse hover moves focus so the two input styles never disagree.
 */
class Nav extends flixel.FlxBasic
{
	var items:Array<Button>;
	var cols:Int;
	var index:Int = 0;

	public function new(items:Array<Button>, cols:Int = 1, start:Int = 0)
	{
		super();
		this.items = items;
		this.cols = cols;
		for (b in items)
			b.onHover = function(btn) focus(items.indexOf(btn), false);
		focus(start, false);
	}

	public function focus(i:Int, sound:Bool = true):Void
	{
		if (items.length == 0)
			return;
		i = Std.int(Math.max(0, Math.min(items.length - 1, i)));
		if (sound && i != index)
			Audio.sfx("hover");
		index = i;
		for (k in 0...items.length)
			items[k].focused = k == index;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		var k = FlxG.keys;
		if (k.anyJustPressed([DOWN, S]))
			focus(index + cols >= items.length ? index : index + cols);
		if (k.anyJustPressed([UP, W]))
			focus(index - cols < 0 ? index : index - cols);
		if (cols > 1 && k.anyJustPressed([RIGHT, D]))
			focus(index + 1);
		if (cols > 1 && k.anyJustPressed([LEFT, A]))
			focus(index - 1);
		if (k.anyJustPressed([ENTER, SPACE, Z]))
			items[index].press();
	}
}
