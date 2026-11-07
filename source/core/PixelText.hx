package core;

import flixel.FlxSprite;

/**
 * Body text in the pixel font. Rendered in white (plus a one-pixel black drop
 * shadow) and tinted with `color`, so recolouring never re-renders.
 */
class PixelText extends FlxSprite
{
	public var text(default, set):String = "";

	/** Characters revealed so far for typewriter text; -1 shows everything. */
	public var visibleChars(default, set):Int = -1;

	public var textWidth(default, null):Float = 0;

	var fieldWidth:Float;
	var px:Int;
	var align:String;
	var shadow:Bool;
	var italic:Bool;

	public function new(x:Float, y:Float, fieldWidth:Float, text:String, px:Int, color:Int, align:String = "left", shadow:Bool = true, italic:Bool = false)
	{
		super(x, y);
		this.fieldWidth = fieldWidth;
		this.px = px;
		this.align = align;
		this.shadow = shadow;
		this.italic = italic;
		antialiasing = false;
		this.text = text;
		this.color = color;
	}

	function set_text(v:String):String
	{
		if (v == null)
			v = "";
		if (v == text && graphic != null)
			return v;
		text = v;
		render();
		return v;
	}

	function set_visibleChars(v:Int):Int
	{
		if (v == visibleChars)
			return v;
		visibleChars = v;
		render();
		return v;
	}

	function render():Void
	{
		var m = PixelFont.measure(text, px, fieldWidth);
		textWidth = m.w;
		var boxW = fieldWidth > 0 ? fieldWidth : m.w;
		var w = Std.int(Math.max(2, Math.ceil(boxW + px)));
		var h = Std.int(Math.max(2, m.h + px * 2));
		if (graphic == null || pixels.width != w || pixels.height != h)
			makeGraphic(w, h, 0x00000000, true);
		else
			pixels.fillRect(pixels.rect, 0x00000000);
		if (shadow)
			PixelFont.drawBitmap(pixels, m.lines, 0, px, px, 0xFF000000, italic, align, boxW, visibleChars);
		PixelFont.drawBitmap(pixels, m.lines, 0, 0, px, 0xFFFFFFFF, italic, align, boxW, visibleChars);
		dirty = true;
	}
}
