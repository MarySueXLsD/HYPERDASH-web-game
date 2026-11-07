package core;

import flixel.FlxSprite;

/**
 * Headings, buttons and stamps. Same pixel font as body text, at bigger whole
 * multiples. No italic: whole-pixel shearing breaks letters at this resolution.
 * `size` is the requested cap height; it snaps to the art grid.
 */
class VecFont
{
	public static function sprite(text:String, size:Float, color:Int = 0xFFF2F2F5, slant:Float = 0.18, glow:Float = 0, ?weight:Float):FlxSprite
	{
		var px = PixelFont.pxFor(size);
		// No italic: whole-pixel shearing breaks letter shapes at this resolution.
		var italic = false;
		var m = PixelFont.measure(text, px);
		var key = 'pf_${text}_${px}_${color}_${italic}_$glow';
		return Art.sprite(key, m.w + px * 2, m.h + px, function(g) PixelFont.drawGraphics(g, text, 0, 0, px, color, italic, "center", m.w), glow, 10,
			null, 0, false, 1);
	}

	public static function width(text:String, size:Float, slant:Float, thick:Float):Int
	{
		return PixelFont.measure(text, PixelFont.pxFor(size)).w + PixelFont.pxFor(size) * 2;
	}

	public static function height(text:String, size:Float, thick:Float):Int
	{
		return PixelFont.measure(text, PixelFont.pxFor(size)).h;
	}

	/** Draws `text` into `g` with its top-left at (x, y). */
	public static function draw(g:openfl.display.Graphics, text:String, size:Float, color:Int, slant:Float, thick:Float, x:Float, y:Float):Void
	{
		var px = PixelFont.pxFor(size);
		PixelFont.drawGraphics(g, text, x, y, px, color, false, "center", PixelFont.measure(text, px).w);
	}

	/** Largest size (stepping down from `max`) at which `text` fits within `width` pixels. */
	public static function fit(text:String, max:Float, width:Float):Float
	{
		var size = max;
		while (size > 21 && measure(text, size) > width)
			size -= 7;
		return size;
	}

	/** Width of a single line of `text` at `size`, in screen pixels. */
	public static function measure(text:String, size:Float):Float
	{
		return PixelFont.measure(text, PixelFont.pxFor(size)).w;
	}
}
