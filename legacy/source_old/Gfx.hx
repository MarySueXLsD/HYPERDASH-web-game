package;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxColor;
import fx.Fx;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class Gfx
{
	public static inline var FONT = "flixel/fonts/monsterrat.ttf";

	public static function label(x:Float, y:Float, w:Float, caption:String, size:Int, color:FlxColor, outline:Bool = true):FlxText
	{
		var text = new FlxText(x, y, w, caption);
		text.setFormat(FONT, size, color, FlxTextAlign.CENTER);
		if (outline)
		{
			text.borderStyle = FlxTextBorderStyle.OUTLINE;
			text.borderColor = 0xFF050814;
			text.borderSize = size >= 48 ? 3 : 2;
		}
		text.shader = Fx.light;
		return text;
	}

	public static function centerIn(text:FlxText, top:Float, height:Float):Void
	{
		text.y = top + (height - text.height) / 2;
	}

	public static function panel(x:Float, y:Float, w:Int, h:Int, color:FlxColor, glow:Bool = true):FlxSprite
	{
		var sprite = new FlxSprite(x, y);
		sprite.makeGraphic(w, h, color);
		if (glow)
			sprite.shader = Fx.light;
		return sprite;
	}

	public static function clipWidth(sprite:FlxSprite, full:Float, ratio:Float):Void
	{
		if (ratio < 0)
			ratio = 0;
		if (ratio > 1)
			ratio = 1;
		var rect = sprite.clipRect;
		if (rect == null)
			rect = new FlxRect(0, 0, full, sprite.height);
		rect.set(0, 0, Math.max(1, full * ratio), sprite.height);
		sprite.clipRect = rect;
	}

	public static function circle(d:Int, color:Int):FlxSprite
	{
		return bake(d, d, function(px) dot(px, d / 2, d / 2, d / 2 - 1, color));
	}

	public static function heart():FlxSprite
	{
		return bake(36, 34, function(px)
		{
			var color = 0xFFE23B4A;
			dot(px, 12, 12, 9, color);
			dot(px, 24, 12, 9, color);
			for (y in 14...32)
			{
				var t = (y - 14) / 18;
				var half = Std.int((1 - t) * 16);
				if (half < 1)
					half = 1;
				fill(px, 18 - half, y, half * 2, 1, color);
			}
		});
	}

	public static function fly():FlxSprite
	{
		return bake(100, 76, function(px)
		{
			dot(px, 22, 30, 18, 0xFFD6E4F0);
			dot(px, 78, 30, 18, 0xFFD6E4F0);
			dot(px, 50, 42, 26, 0xFF2A2A30);
			dot(px, 40, 36, 4, 0xFFFFFFFF);
			dot(px, 58, 36, 4, 0xFFFFFFFF);
		});
	}

	public static function person():FlxSprite
	{
		return bake(90, 170, function(px)
		{
			dot(px, 45, 32, 26, 0xFF3DDC97);
			fill(px, 18, 62, 54, 100, 0xFF3DDC97);
		});
	}

	public static function coin():FlxSprite
	{
		return bake(110, 110, function(px)
		{
			dot(px, 55, 55, 52, 0xFFF2C14E);
			dot(px, 55, 55, 36, 0xFFFFE7A3);
			dot(px, 55, 55, 10, 0xFFF2C14E);
		});
	}

	public static function face(smile:Bool):FlxSprite
	{
		return bake(210, 210, function(px)
		{
			dot(px, 105, 105, 100, smile ? 0xFFFFD23F : 0xFFE6E0D6);
			if (smile)
			{
				dot(px, 72, 88, 12, 0xFF1A1A1A);
				dot(px, 138, 88, 12, 0xFF1A1A1A);
				for (deg in 20...161)
				{
					var rad = deg * Math.PI / 180;
					dot(px, 105 + Math.cos(rad) * 48, 118 + Math.sin(rad) * 36, 5, 0xFF1A1A1A);
				}
			}
			else
			{
				dot(px, 70, 90, 22, 0xFF1A1A1A);
				dot(px, 140, 90, 22, 0xFF1A1A1A);
				dot(px, 105, 124, 8, 0xFF1A1A1A);
				fill(px, 62, 148, 86, 28, 0xFF1A1A1A);
				for (i in 0...4)
					fill(px, 70 + i * 20, 151, 8, 22, 0xFFE6E0D6);
			}
		});
	}

	public static function arrow(dir:String):FlxSprite
	{
		var size = 200;
		return bake(size, size, function(px)
		{
			var color = 0xFFF2C14E;
			var src = new BitmapData(size, size, true, 0x00000000);
			src.fillRect(new Rectangle(82, 90, 36, 88), color);
			for (y in 18...112)
			{
				var half = Std.int(6 + ((y - 18) / 94) * 78);
				src.fillRect(new Rectangle(100 - half, y, half * 2, 1), color);
			}
			var cx = (size - 1) / 2;
			for (y in 0...size)
			{
				for (x in 0...size)
				{
					var pixel = src.getPixel32(x, y);
					if ((pixel >>> 24) == 0)
						continue;
					var dx = x - cx;
					var dy = y - cx;
					var rx = dx;
					var ry = dy;
					switch (dir)
					{
						case "right":
							rx = -dy;
							ry = dx;
						case "down":
							rx = -dx;
							ry = -dy;
						case "left":
							rx = dy;
							ry = -dx;
						default:
					}
					var ox = Std.int(cx + rx);
					var oy = Std.int(cx + ry);
					if (ox >= 0 && oy >= 0 && ox < size && oy < size)
						px.setPixel32(ox, oy, color);
				}
			}
			src.dispose();
		});
	}

	static function bake(w:Int, h:Int, draw:BitmapData->Void):FlxSprite
	{
		var sprite = new FlxSprite();
		sprite.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		sprite.shader = Fx.light;
		var pixels = sprite.pixels;
		pixels.lock();
		draw(pixels);
		pixels.unlock();
		return sprite;
	}

	static function dot(px:BitmapData, cx:Float, cy:Float, r:Float, color:Int):Void
	{
		var r2 = r * r;
		var x0 = Std.int(Math.max(0, cx - r));
		var y0 = Std.int(Math.max(0, cy - r));
		var x1 = Std.int(Math.min(px.width - 1, cx + r));
		var y1 = Std.int(Math.min(px.height - 1, cy + r));
		for (y in y0...y1 + 1)
		{
			for (x in x0...x1 + 1)
			{
				var dx = x + 0.5 - cx;
				var dy = y + 0.5 - cy;
				if (dx * dx + dy * dy <= r2)
					px.setPixel32(x, y, color);
			}
		}
	}

	static function fill(px:BitmapData, x:Int, y:Int, w:Int, h:Int, color:Int):Void
	{
		if (w <= 0 || h <= 0)
			return;
		px.fillRect(new Rectangle(x, y, w, h), color);
	}
}
