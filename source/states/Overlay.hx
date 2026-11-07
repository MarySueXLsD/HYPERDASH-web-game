package states;

import core.Art;
import core.Audio;
import core.G;
import core.Ui;
import core.VecFont;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

typedef OverlayItem =
{
	var label:Void->String;
	var action:Button->Void;
	@:optional var primary:Bool;
}

/**
 * Modal paper slip with a heading, optional body text and a stack of label
 * buttons. Pushed on top of a state (pause, options, credits); input goes to
 * the top-most slip and Escape always backs out.
 */
class Overlay extends FlxSubState
{
	var heading:String;
	var body:String;
	var items:Array<OverlayItem>;
	var buttons:Array<Button> = [];
	var closing:Bool = false;
	var nav:Nav;

	public var onClose:Void->Void;

	public function new(heading:String, items:Array<OverlayItem>, ?body:String)
	{
		super(0xC0080612);
		this.heading = heading;
		this.items = items;
		this.body = body;
	}

	override public function create():Void
	{
		super.create();
		var bodyText:core.PixelText = body == null ? null : Ui.text(0, 0, 380, body, 16, 0xFF4A4458, "left");
		var bodyH = bodyText == null ? 0 : Std.int(bodyText.height + 24);
		var h = 140 + bodyH + items.length * 86;
		var top = (G.H - h) / 2;
		var slip = Art.receipt(460, Std.int(h + 30));
		slip.setPosition((G.W - 460) / 2, top - 20);
		add(slip);
		var head = VecFont.sprite(heading, 34, G.INK, 0.12, 0, 5);
		head.setPosition(slip.x + 40, top + 28);
		add(head);
		var y = top + 92;
		if (body != null)
		{
			bodyText.setPosition(slip.x + 40, y);
			add(bodyText);
			y += bodyH;
		}
		for (it in items)
		{
			var b:Button = null;
			b = new Button(G.W / 2 - 190, y, 380, 70, it.label(), it.primary == true, function() it.action(b), 22);
			buttons.push(b);
			add(b);
			y += 86;
		}
		nav = new Nav(buttons);
		add(nav);

		var all = members.copy();
		for (i in 0...all.length)
		{
			var m = all[i];
			if (Std.isOfType(m, FlxSprite))
			{
				var s:FlxSprite = cast m;
				s.scrollFactor.set(0, 0);
				var y0 = s.y;
				s.y += G.H * 0.6;
				FlxTween.tween(s, {y: y0}, 0.38, {startDelay: i * 0.012, ease: FlxEase.backOut});
			}
		}
		Audio.sfx("swipe");
		Audio.setDuck(0.35);
	}

	public static function options(owner:BaseState):Overlay
	{
		var o:Overlay = null;
		var wipeArmed = false;
		inline function onOff(v:Bool)
			return v ? "ON" : "OFF";
		o = new Overlay("Options", [
			{
				label: () -> "MUSIC  " + onOff(G.musicOn),
				action: function(_)
				{
					G.musicOn = !G.musicOn;
					G.saveSettings();
					Audio.applySettings();
					o.refresh();
				}
			},
			{
				label: () -> "SOUND  " + onOff(G.sfxOn),
				action: function(_)
				{
					G.sfxOn = !G.sfxOn;
					G.saveSettings();
					Audio.applySettings();
					o.refresh();
				}
			},
			{
				label: () -> "SHAKE  " + onOff(G.shakeOn),
				action: function(_)
				{
					G.shakeOn = !G.shakeOn;
					G.saveSettings();
					if (G.shakeOn)
						core.Juice.shake(0.5);
					o.refresh();
				}
			},
			{
				label: () -> "FLASHES  " + onOff(G.screenFx),
				action: function(_)
				{
					G.screenFx = !G.screenFx;
					G.saveSettings();
					owner.applyPost();
					o.refresh();
				}
			},
			{
				label: () -> wipeArmed ? "CONFIRM ERASE" : "ERASE RECORDS",
				action: function(_)
				{
					if (wipeArmed)
					{
						G.wipeSave();
						wipeArmed = false;
						Audio.sfx("boom");
					}
					else
						wipeArmed = true;
					o.refresh();
				}
			},
			{label: () -> "DONE", primary: true, action: function(_) o.dismiss()}
		]);
		return o;
	}

	public function refresh():Void
	{
		for (i in 0...items.length)
			buttons[i].setCaption(items[i].label(), 22);
	}

	public function dismiss():Void
	{
		if (closing)
			return;
		closing = true;
		Audio.setDuck(1);
		Audio.sfx("back");
		if (onClose != null)
			onClose();
		close();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE)
			dismiss();
	}
}
