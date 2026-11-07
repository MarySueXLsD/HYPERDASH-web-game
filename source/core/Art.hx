package core;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display.CapsStyle;
import openfl.display.GradientType;
import openfl.display.Graphics;
import openfl.display.JointStyle;
import openfl.display.Shape;
import openfl.filters.BlurFilter;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Generated pixel art. Shapes are described with the openfl Graphics API, then
 * rasterised onto a coarse pixel grid with one shared palette and cached for
 * the whole session.
 */
class Art
{
	static var origin = new Point();

	/** Screen pixels per art pixel. Everything in the game shares this one grid. */
	public static inline var PX:Int = 2;

	/**
	 * The shared palette. Every generated sprite is snapped to these colours so
	 * ships, UI, effects and type all read as one hand-pixelled set.
	 */
	static var PALETTE:Array<Int> = [
		0x000000, 0x120E22, 0x211C2B, 0x2B2440, 0x3A3352, 0x5A5468, 0x8A83A6, 0xC9C2DE, 0xF2F2F5,
		0xEEEAE0, 0xD9B98A, 0xB8935A, 0x8A6A3A, 0x5A4A3A, 0x2A1E2E,
		0xFF5B1F, 0xFF9A3C, 0xFFC21A, 0xFFE45C, 0xFFF4A0, 0xFFB07A,
		0xE5343F, 0x8A1C28, 0xE0457B, 0x6A1C40,
		0x58D68D, 0x2FA866, 0x1C5A3A, 0xC8FF4D, 0x4A8A1C,
		0x3FD6C2, 0x9AF0E4, 0x1C6A6A, 0x3CF0FF,
		0x2A3C9A, 0x5A7AE0, 0x8C6CFF, 0x4A2C8A, 0x1A1050, 0x14204A, 0x0A3A24
	];

	static var nearest:Map<Int, Int> = new Map();
	static var pixelRect = new Rectangle(0, 0, PX, PX);

	static function snap(rgb:Int):Int
	{
		var hit = nearest.get(rgb);
		if (hit != null)
			return hit;
		var r = (rgb >> 16) & 0xFF;
		var g = (rgb >> 8) & 0xFF;
		var b = rgb & 0xFF;
		var best = PALETTE[0];
		var bestD = 1e9;
		for (c in PALETTE)
		{
			var dr = r - ((c >> 16) & 0xFF);
			var dg = g - ((c >> 8) & 0xFF);
			var db = b - (c & 0xFF);
			var d = dr * dr * 0.3 + dg * dg * 0.59 + db * db * 0.11;
			if (d < bestD)
			{
				bestD = d;
				best = c;
			}
		}
		nearest.set(rgb, best);
		return best;
	}

	/**
	 * Draws `draw` (vector commands in screen pixels, content `w`×`h`) as real
	 * pixel art: rasterised at 1/PX resolution, alpha snapped to on/off, colours
	 * snapped to the palette, then blown up with hard edges. `glow` adds a
	 * dithered one-pixel halo instead of a soft bloom. `rot` (degrees) is baked
	 * in, so tilted stamps stay on the grid. `raw` skips the palette (portraits).
	 */
	public static function graphic(key:String, w:Int, h:Int, draw:Graphics->Void, glow:Float = 1, blur:Float = 10, ?post:BitmapData->Void,
			rot:Float = 0, raw:Bool = false, zoom:Float = 1, pixel:Int = 0):FlxGraphic
	{
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;
		var PX = pixel > 0 ? pixel : Art.PX;
		var pad = glow > 0 ? 2 : 1;
		var rad = rot * Math.PI / 180;
		var cs = Math.abs(Math.cos(rad));
		var sn = Math.abs(Math.sin(rad));
		var rw = w * cs + h * sn;
		var rh = w * sn + h * cs;
		var lw = Std.int(Math.ceil(rw / PX)) + pad * 2;
		var lh = Std.int(Math.ceil(rh / PX)) + pad * 2;

		var shape = new Shape();
		draw(shape.graphics);
		var base = new BitmapData(lw, lh, true, 0);
		var m = new Matrix();
		m.scale(zoom, zoom);
		m.translate(-w / 2, -h / 2);
		m.rotate(rad);
		m.translate(rw / 2, rh / 2);
		m.scale(1 / PX, 1 / PX);
		m.translate(pad, pad);
		base.draw(shape, m, null, null, null, false);
		if (post != null)
			post(base);

		// Hard alpha + palette.
		base.lock();
		for (y in 0...lh)
			for (x in 0...lw)
			{
				var p = base.getPixel32(x, y);
				var a = (p >>> 24) & 0xFF;
				if (a < 96)
					base.setPixel32(x, y, 0);
				else
					base.setPixel32(x, y, 0xFF000000 | (raw ? (p & 0xFFFFFF) : snap(p & 0xFFFFFF)));
			}
		base.unlock();

		// Dithered halo for light sources: every other empty pixel touching the sprite.
		if (glow > 0)
		{
			var src = base.clone();
			base.lock();
			for (y in 0...lh)
				for (x in 0...lw)
				{
					if ((x + y) % 2 != 0 || (src.getPixel32(x, y) >>> 24) != 0)
						continue;
					var n = 0;
					for (d in [[1, 0], [-1, 0], [0, 1], [0, -1]])
					{
						var nx = x + d[0];
						var ny = y + d[1];
						if (nx >= 0 && ny >= 0 && nx < lw && ny < lh && (src.getPixel32(nx, ny) >>> 24) != 0)
							n = src.getPixel32(nx, ny);
					}
					if (n != 0)
						base.setPixel32(x, y, 0x90000000 | (n & 0xFFFFFF));
				}
			base.unlock();
			src.dispose();
		}

		// Blow up to screen pixels with hard edges.
		var out = new BitmapData(lw * PX, lh * PX, true, 0);
		pixelRect.width = pixelRect.height = PX;
		out.lock();
		for (y in 0...lh)
			for (x in 0...lw)
			{
				var p = base.getPixel32(x, y);
				if ((p >>> 24) == 0)
					continue;
				pixelRect.x = x * PX;
				pixelRect.y = y * PX;
				out.fillRect(pixelRect, p);
			}
		out.unlock();
		base.dispose();
		var g = FlxGraphic.fromBitmapData(out, false, key);
		g.persist = true;
		g.destroyOnNoUse = false;
		return g;
	}

	public static function sprite(key:String, w:Int, h:Int, draw:Graphics->Void, glow:Float = 1, blur:Float = 10, ?post:BitmapData->Void,
			rot:Float = 0, raw:Bool = false, pixel:Int = 0):FlxSprite
	{
		var s = new FlxSprite();
		s.loadGraphic(graphic(key, w, h, draw, glow, blur, post, rot, raw, 1, pixel));
		s.antialiasing = false;
		return s;
	}

	public static function center(s:FlxSprite, x:Float, y:Float):FlxSprite
	{
		s.x = x - s.width / 2;
		s.y = y - s.height / 2;
		return s;
	}

	public static inline function cx(s:FlxSprite):Float
	{
		return s.x + s.width / 2;
	}

	public static inline function cy(s:FlxSprite):Float
	{
		return s.y + s.height / 2;
	}

	// ------------------------------------------------------------ primitives

	public static function line(g:Graphics, thick:Float, color:Int, alpha:Float = 1):Void
	{
		g.lineStyle(thick, color & 0xFFFFFF, alpha, false, null, CapsStyle.ROUND, JointStyle.ROUND);
	}

	public static function fill(g:Graphics, color:Int, alpha:Float = 1):Void
	{
		g.beginFill(color & 0xFFFFFF, alpha);
	}

	public static function poly(g:Graphics, pts:Array<Float>, close:Bool = true):Void
	{
		g.moveTo(pts[0], pts[1]);
		var i = 2;
		while (i < pts.length)
		{
			g.lineTo(pts[i], pts[i + 1]);
			i += 2;
		}
		if (close)
			g.lineTo(pts[0], pts[1]);
	}

	public static function chamfer(g:Graphics, x:Float, y:Float, w:Float, h:Float, c:Float):Void
	{
		poly(g, [x + c, y, x + w - c, y, x + w, y + c, x + w, y + h - c, x + w - c, y + h, x + c, y + h, x, y + h - c, x, y + c]);
	}

	public static function radial(g:Graphics, x:Float, y:Float, r:Float, inner:Int, outer:Int, innerA:Float = 1, outerA:Float = 0):Void
	{
		var m = new Matrix();
		m.createGradientBox(r * 2, r * 2, 0, x - r, y - r);
		g.beginGradientFill(GradientType.RADIAL, [inner & 0xFFFFFF, outer & 0xFFFFFF], [innerA, outerA], [0, 255], m);
		g.drawCircle(x, y, r);
		g.endFill();
	}

	public static function hexPts(x:Float, y:Float, r:Float, rot:Float = 0):Array<Float>
	{
		var pts = [];
		for (i in 0...6)
		{
			var a = rot + i * Math.PI / 3;
			pts.push(x + Math.cos(a) * r);
			pts.push(y + Math.sin(a) * r);
		}
		return pts;
	}

	// --------------------------------------------------------------- library

	/** Soft white dot for particles. */
	public static function dot():FlxGraphic
	{
		return graphic("dot", 32, 32, function(g) radial(g, 16, 16, 16, 0xFFFFFF, 0xFFFFFF, 1, 0), 0);
	}

	public static function spark():FlxGraphic
	{
		return graphic("spark", 24, 6, function(g)
		{
			fill(g, 0xFFFFFF);
			g.drawEllipse(0, 0, 24, 6);
			g.endFill();
		}, 1, 4);
	}

	public static function ring():FlxGraphic
	{
		return graphic("ring", 128, 128, function(g)
		{
			line(g, 6, 0xFFFFFF);
			g.drawCircle(64, 64, 60);
		}, 1, 8);
	}

	/** A 64px glowing line with its origin on the left, scaled to any length. */
	public static function beam(thick:Float = 4):FlxSprite
	{
		var s = sprite("beam" + thick, 64, Std.int(thick + 2), function(g)
		{
			fill(g, 0xFFFFFF);
			g.drawRect(0, 1, 64, thick);
			g.endFill();
		}, 2, 6);
		s.origin.set(0, s.height / 2);
		return s;
	}

	public static function setBeam(b:FlxSprite, x1:Float, y1:Float, x2:Float, y2:Float):Void
	{
		var dx = x2 - x1;
		var dy = y2 - y1;
		var len = Math.sqrt(dx * dx + dy * dy);
		b.x = x1;
		b.y = y1 - b.height / 2;
		b.scale.x = Math.max(0.01, len / b.frameWidth);
		b.angle = Math.atan2(dy, dx) * 180 / Math.PI;
	}

	public static function panel(w:Int, h:Int, fillColor:Int, stroke:Int, fillAlpha:Float = 0.85, cut:Float = 14, thick:Float = 2.5):FlxSprite
	{
		var key = 'panel_${w}_${h}_${fillColor}_${stroke}_${fillAlpha}_${cut}_$thick';
		return sprite(key, w, h, function(g)
		{
			fill(g, fillColor, fillAlpha);
			line(g, thick, stroke);
			chamfer(g, thick / 2, thick / 2, w - thick, h - thick, cut);
			g.endFill();
		}, 1, 8);
	}

	public static function hexCell(full:Bool):FlxSprite
	{
		return sprite("hex" + full, 34, 38, function(g)
		{
			var pts = hexPts(17, 19, 17, Math.PI / 6);
			if (full)
				fill(g, G.CYAN, 0.9);
			else
				fill(g, 0x101830, 0.8);
			line(g, 2.5, full ? 0xFFFFFF : 0x3A4A70);
			poly(g, pts);
			g.endFill();
		}, full ? 1 : 0, 8);
	}

	public static function shipPts():Array<Float>
	{
		return [42, 0, 52, 30, 58, 56, 82, 84, 84, 100, 60, 96, 54, 108, 30, 108, 24, 96, 0, 100, 2, 84, 26, 56, 32, 30];
	}

	/** The hero courier ship, nose up: an ink hull, safety-orange livery and a parcel pod on its back. */
	public static function ship(tint:Int = 0xFF5A7AE0, key:String = "ship"):FlxSprite
	{
		return sprite(key, 84, 110, function(g)
		{
			fill(g, 0x2B2440);
			line(g, 3, 0xF2F2F5);
			poly(g, shipPts());
			g.endFill();
			g.lineStyle();
			fill(g, tint);
			poly(g, [26, 58, 2, 86, 2, 92, 30, 66]);
			poly(g, [58, 58, 82, 86, 82, 92, 54, 66]);
			g.endFill();
			fill(g, 0xD9B98A);
			line(g, 2, 0x211C2B);
			g.drawRect(33, 66, 18, 20);
			g.endFill();
			line(g, 2, 0x8A6A3A);
			poly(g, [42, 66, 42, 86], false);
			g.lineStyle();
			fill(g, 0x3FD6C2);
			g.drawEllipse(36, 24, 12, 24);
			g.endFill();
			fill(g, 0xFFFFFF, 0.85);
			g.drawEllipse(38.5, 28, 3.5, 9);
			g.endFill();
		}, 1, 6);
	}

	public static function flame():FlxSprite
	{
		var s = sprite("flame", 30, 70, function(g)
		{
			fill(g, 0xFF7A2C, 0.9);
			poly(g, [0, 0, 30, 0, 15, 70]);
			g.endFill();
			fill(g, 0xFFE45C);
			poly(g, [6, 0, 24, 0, 15, 44]);
			g.endFill();
			fill(g, 0xFFFFFF);
			poly(g, [10, 0, 20, 0, 15, 22]);
			g.endFill();
		}, 2, 8);
		s.origin.set(s.width / 2, 12);
		s.blend = openfl.display.BlendMode.ADD;
		return s;
	}

	public static function rock(i:Int, r:Float):FlxSprite
	{
		var size = Std.int(r * 2 + 4);
		return sprite('rock_${i}_$r', size, size, function(g)
		{
			var rnd = new flixel.math.FlxRandom(i * 977 + 13);
			var pts = [];
			var n = 9;
			for (k in 0...n)
			{
				var a = k / n * Math.PI * 2;
				var rr = r * rnd.float(0.72, 1);
				pts.push(size / 2 + Math.cos(a) * rr);
				pts.push(size / 2 + Math.sin(a) * rr);
			}
			fill(g, 0x2A1E2E);
			line(g, 3, 0xFFB07A);
			poly(g, pts);
			g.endFill();
			line(g, 2, 0x8A5A5A);
			for (k in 0...3)
			{
				var a = rnd.float(0, Math.PI * 2);
				var d = rnd.float(0, r * 0.45);
				g.drawCircle(size / 2 + Math.cos(a) * d, size / 2 + Math.sin(a) * d, r * rnd.float(0.1, 0.2));
			}
		}, 1, 8);
	}

	public static function drone():FlxSprite
	{
		return sprite("drone", 76, 60, function(g)
		{
			fill(g, 0x2A0C1C);
			line(g, 3, 0xE5343F);
			poly(g, [38, 6, 70, 24, 60, 52, 16, 52, 6, 24]);
			g.endFill();
			line(g, 2.5, 0xE5343F);
			poly(g, [0, 30, 10, 20], false);
			poly(g, [76, 30, 66, 20], false);
			g.lineStyle();
			fill(g, 0xFFE45C);
			g.drawCircle(38, 30, 9);
			g.endFill();
			fill(g, 0xFFFFFF);
			g.drawCircle(38, 30, 4);
			g.endFill();
		}, 1, 8);
	}

	/** Corsair ship, nose down. */
	public static function pirate():FlxSprite
	{
		return sprite("pirate", 100, 86, function(g)
		{
			fill(g, 0x2A0A10);
			line(g, 3, 0xE5343F);
			poly(g, [50, 86, 64, 50, 100, 30, 86, 0, 60, 14, 40, 14, 14, 0, 0, 30, 36, 50]);
			g.endFill();
			line(g, 2, 0xFFB03C);
			poly(g, [40, 22, 60, 22, 50, 54]);
			g.lineStyle();
			fill(g, 0xFF3B5C);
			g.drawCircle(50, 34, 6);
			g.endFill();
		}, 1, 8);
	}

	public static function cell():FlxSprite
	{
		return sprite("cell", 44, 56, function(g)
		{
			fill(g, 0x0C2A1C);
			line(g, 3, 0x4DFF9A);
			chamfer(g, 6, 2, 32, 52, 8);
			g.endFill();
			g.lineStyle();
			fill(g, 0x4DFF9A);
			poly(g, [24, 10, 14, 30, 22, 30, 18, 46, 30, 24, 22, 24]);
			g.endFill();
		}, 1, 8);
	}

	public static function parcel():FlxSprite
	{
		return sprite("parcel", 80, 70, function(g)
		{
			fill(g, 0xD9B98A);
			line(g, 3, 0x211C2B);
			g.drawRect(2, 8, 76, 60);
			g.endFill();
			g.lineStyle();
			fill(g, 0xB8935A);
			g.drawRect(34, 8, 12, 60);
			g.endFill();
			fill(g, 0xEEEAE0);
			line(g, 2, 0x211C2B);
			g.drawRect(8, 40, 22, 20);
			g.endFill();
			line(g, 1.5, 0x211C2B);
			for (i in 0...5)
				poly(g, [11 + i * 4, 44, 11 + i * 4, 52], false);
		}, 0);
	}

	public static function duck():FlxSprite
	{
		return sprite("duck", 90, 80, function(g)
		{
			fill(g, 0xFFD23C);
			line(g, 3, 0xFFF4A0);
			g.drawEllipse(6, 34, 76, 42);
			g.drawCircle(58, 26, 20);
			g.endFill();
			g.lineStyle();
			fill(g, 0xFF7A2C);
			poly(g, [74, 22, 90, 28, 74, 34]);
			g.endFill();
			fill(g, 0x101010);
			g.drawCircle(62, 20, 4);
			g.endFill();
		}, 1, 8);
	}

	// ---------------------------------------------------------------- UI kit

	/** Shipping-label button: flat fill, ink outline, hard offset shadow, a punched tag hole. */
	public static function label(w:Int, h:Int, fillColor:Int):FlxSprite
	{
		return sprite('label_${w}_${h}_$fillColor', w, h, function(g)
		{
			g.lineStyle();
			fill(g, 0x000000, 0.45);
			chamfer(g, 6, 7, w - 6, h - 7, 9);
			g.endFill();
			fill(g, fillColor);
			line(g, 3, 0x211C2B);
			chamfer(g, 1.5, 1.5, w - 9, h - 9, 9);
			g.endFill();
			fill(g, 0x120E22);
			line(g, 2, 0x211C2B);
			g.drawCircle(17, (h - 7) / 2, 5);
			g.endFill();
		}, 0);
	}

	/** Hazard-yellow outline drawn around the focused control. */
	public static function focusFrame(w:Int, h:Int):FlxSprite
	{
		return sprite('focus_${w}_$h', w, h, function(g)
		{
			line(g, 4, 0xFFC21A);
			chamfer(g, 2, 2, w - 4, h - 4, 10);
		}, 0);
	}

	/** Paper slip with torn zig-zag top and bottom edges. */
	public static function receipt(w:Int, h:Int, paper:Int = 0xFFEEEAE0):FlxSprite
	{
		return sprite('receipt_${w}_${h}_$paper', w, h, function(g)
		{
			var tooth = 14.0;
			var n = Std.int(w / tooth);
			var pts:Array<Float> = [];
			for (i in 0...n + 1)
			{
				pts.push(i * tooth);
				pts.push(i % 2 == 0 ? 8 : 0);
			}
			for (i in 0...n + 1)
			{
				var k = n - i;
				pts.push(k * tooth);
				pts.push(k % 2 == 0 ? h - 16 : h - 8);
			}
			g.lineStyle();
			fill(g, 0x000000, 0.4);
			var shadow = [for (i in 0...pts.length) pts[i] + (i % 2 == 0 ? 6 : 8)];
			poly(g, shadow);
			g.endFill();
			fill(g, paper);
			poly(g, pts);
			g.endFill();
		}, 0);
	}

	/** A route ticket: paper with notches on both sides and a perforated tear line. */
	public static function ticket(w:Int, h:Int):FlxSprite
	{
		return sprite('ticket_${w}_$h', w, h, function(g)
		{
			g.lineStyle();
			fill(g, 0x000000, 0.45);
			g.drawRect(6, 8, w - 6, h - 8);
			g.endFill();
			fill(g, 0xEEEAE0);
			g.drawRect(0, 0, w - 6, h - 8);
			g.endFill();
			fill(g, 0x120E22);
			g.drawCircle(0, (h - 8) / 2, 18);
			g.drawCircle(w - 6, (h - 8) / 2, 18);
			g.endFill();
			fill(g, 0xFF5B1F);
			g.drawRect(0, 0, w - 6, 14);
			g.endFill();
			fill(g, 0x211C2B, 0.35);
			var x = 28.0;
			while (x < w - 34)
			{
				g.drawRect(x, h - 40, 8, 2);
				x += 14;
			}
			g.endFill();
		}, 0);
	}

	/** One unit of cargo. Four of them are the player's lives. */
	public static function cargo(intact:Bool, small:Bool = false):FlxGraphic
	{
		var k = small ? 0.6 : 1.0;
		return graphic("cargo" + intact + small, Std.int(40 * k) + 1, Std.int(36 * k) + 1, function(g)
		{
			if (intact)
			{
				fill(g, 0xD9B98A);
				line(g, 3, 0x211C2B);
				g.drawRect(2, 6, 36, 28);
				g.endFill();
				g.lineStyle();
				fill(g, 0xB8935A);
				g.drawRect(16, 6, 8, 28);
				g.endFill();
				line(g, 3, 0x211C2B);
				poly(g, [0, 6, 6, 0, 34, 0, 40, 6], false);
			}
			else
			{
				fill(g, 0x5A4A3A, 0.8);
				line(g, 3, 0x211C2B);
				poly(g, [2, 34, 6, 18, 14, 22, 22, 12, 30, 20, 38, 16, 38, 34]);
				g.endFill();
				line(g, 3, 0xE5343F);
				poly(g, [12, 20, 28, 32], false);
				poly(g, [28, 20, 12, 32], false);
			}
		}, 0, 10, null, 0, false, k);
	}

	/** Speedometer face: a 270° arc of ticks from warp 1 to 3, the last third marked red. */
	public static function dial(r:Int):FlxSprite
	{
		var size = r * 2 + 8;
		return sprite("dial" + r, size, size, function(g)
		{
			var c = size / 2;
			g.lineStyle();
			fill(g, 0x120E22, 0.85);
			g.drawCircle(c, c, r);
			g.endFill();
			line(g, 3, 0x9A93B8, 0.5);
			g.drawCircle(c, c, r);
			var a0 = Math.PI * 0.75;
			var sweep = Math.PI * 1.5;
			for (i in 0...41)
			{
				var t = i / 40;
				var a = a0 + sweep * t;
				var major = i % 10 == 0;
				var hot = t > 0.66;
				line(g, major ? 4 : 2, hot ? 0xE5343F : 0xF2F2F5, major ? 1 : 0.6);
				var r1 = r - (major ? 22 : 12);
				var r2 = r - 6;
				poly(g, [c + Math.cos(a) * r1, c + Math.sin(a) * r1, c + Math.cos(a) * r2, c + Math.sin(a) * r2], false);
			}
		}, 0);
	}

	/** Speedometer needle pointing right; rotate it around its hub (the sprite origin). */
	public static function needle(len:Int):FlxSprite
	{
		var s = sprite("needle" + len, len + 14, 14, function(g)
		{
			g.lineStyle();
			fill(g, 0xFF5B1F);
			poly(g, [7, 3, len + 7, 7, 7, 11]);
			g.endFill();
			fill(g, 0xF2F2F5);
			g.drawCircle(7, 7, 7);
			g.endFill();
		}, 1, 5);
		var pad = (s.width - (len + 14)) / 2;
		s.origin.set(pad + 7, s.height / 2);
		return s;
	}

	public static function hazard(w:Int, h:Int):FlxSprite
	{
		return sprite('hazard_${w}_$h', w, h, function(g)
		{
			g.lineStyle();
			fill(g, 0xFFC21A);
			g.drawRect(0, 0, w, h);
			g.endFill();
			fill(g, 0x211C2B);
			var x = -h * 1.0;
			while (x < w)
			{
				poly(g, [x, h, x + h, 0, x + h + 18, 0, x + 18, h]);
				x += 36;
			}
			g.endFill();
		}, 0);
	}

	/**
	 * Rubber stamp: heavy stencil text inside a double frame, then distressed
	 * with noise so the ink looks pressed rather than printed.
	 */
	public static function stamp(text:String, size:Float, color:Int, framed:Bool = true, rot:Float = 0, stencil:Bool = false):FlxSprite
	{
		if (stencil)
			return stencilStamp(text, size, color, rot);
		var slant = 0.0;
		rot = 0;
		var thick = size * 0.2;
		var tw = VecFont.width(text, size, slant, thick);
		var th = VecFont.height(text, size, thick);
		var padX = framed ? size * 0.42 : 4;
		var padY = framed ? size * 0.32 : 4;
		var w = Std.int(tw + padX * 2);
		var h = Std.int(th + padY * 2);
		var seed = 0;
		for (i in 0...text.length)
			seed += text.charCodeAt(i) * (i + 3);
		var s = sprite('stamp_${text}_${size}_${color}_${framed}_$rot', w, h, function(g)
		{
			if (framed)
			{
				var lw = Math.max(3, size * 0.1);
				line(g, lw, color);
				g.drawRoundRect(lw / 2, lw / 2, w - lw, h - lw, size * 0.25, size * 0.25);
				line(g, Math.max(1.5, lw * 0.4), color);
				g.drawRoundRect(lw * 1.8, lw * 1.8, w - lw * 3.6, h - lw * 3.6, size * 0.18, size * 0.18);
			}
			VecFont.draw(g, text, size, color, slant, thick, padX, padY);
		}, 0, 4, size >= 30 ? function(b) distress(b, seed) : null, rot, false, 1);
		return s;
	}

	/** Framed stamp lettered with the stroke stencil, drawn at full resolution with a baked tilt. */
	static function stencilStamp(text:String, size:Float, color:Int, rot:Float):FlxSprite
	{
		var thick = Math.max(3, size * 0.2);
		var tw = StrokeFont.width(text, size, thick);
		var th = Std.int(size + thick * 2);
		var padX = size * 0.42;
		var padY = size * 0.32;
		var w = Std.int(tw + padX * 2);
		var h = Std.int(th + padY * 2);
		return sprite('stencil_${text}_${size}_${color}_$rot', w, h, function(g)
		{
			var lw = Math.max(3, size * 0.1);
			line(g, lw, color);
			g.drawRoundRect(lw / 2, lw / 2, w - lw, h - lw, size * 0.25, size * 0.25);
			line(g, Math.max(1.5, lw * 0.4), color);
			g.drawRoundRect(lw * 1.8, lw * 1.8, w - lw * 3.6, h - lw * 3.6, size * 0.18, size * 0.18);
			StrokeFont.draw(g, text, size, color, thick, padX, padY);
		}, 0, 4, null, rot, false, 1);
	}

	static inline function hash(x:Float, y:Float, seed:Float):Float
	{
		var v = Math.sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453;
		return v - Math.floor(v);
	}

	static function smooth(x:Float, y:Float, seed:Float):Float
	{
		var ix = Math.floor(x);
		var iy = Math.floor(y);
		var fx = x - ix;
		var fy = y - iy;
		fx = fx * fx * (3 - 2 * fx);
		fy = fy * fy * (3 - 2 * fy);
		var a = hash(ix, iy, seed);
		var b = hash(ix + 1, iy, seed);
		var c = hash(ix, iy + 1, seed);
		var d = hash(ix + 1, iy + 1, seed);
		var top = a + (b - a) * fx;
		var bot = c + (d - c) * fx;
		return top + (bot - top) * fy;
	}

	/** Knocks holes in the ink: blotchy wear plus fine speckle. */
	static function distress(b:BitmapData, seed:Int):Void
	{
		b.lock();
		for (y in 0...b.height)
			for (x in 0...b.width)
			{
				var px = b.getPixel32(x, y);
				var a = (px >>> 24) & 0xFF;
				if (a == 0)
					continue;
				var n = smooth(x / 8, y / 8, seed) * 0.7 + hash(Std.int(x / 2), Std.int(y / 2), seed) * 0.3;
				if (n < 0.16)
					b.setPixel32(x, y, 0);
				else if (n < 0.24)
					b.setPixel32(x, y, (px & 0xFFFFFF) | (Std.int(a * 0.45) << 24));
			}
		b.unlock();
	}

	// ------------------------------------------------------------ set pieces

	public static function station():FlxSprite
	{
		return sprite("station", 460, 300, function(g)
		{
			var cx = 230.0;
			var cy = 150.0;
			line(g, 6, 0x3A4A80);
			g.drawEllipse(cx - 220, cy - 70, 440, 140);
			line(g, 2, 0x3CF0FF);
			g.drawEllipse(cx - 220, cy - 70, 440, 140);
			line(g, 3, 0x3A4A80);
			for (i in 0...6)
			{
				var a = i * Math.PI / 3;
				poly(g, [cx, cy, cx + Math.cos(a) * 216, cy + Math.sin(a) * 68], false);
			}
			fill(g, 0x101830);
			line(g, 3, 0xEAF6FF);
			chamfer(g, cx - 60, cy - 90, 120, 180, 20);
			g.endFill();
			line(g, 2, 0x3CF0FF);
			chamfer(g, cx - 40, cy - 70, 80, 60, 10);
			g.lineStyle();
			for (i in 0...12)
			{
				var a = i * Math.PI / 6;
				fill(g, i % 2 == 0 ? 0xFFE45C : 0xFF3CAC);
				g.drawCircle(cx + Math.cos(a) * 220, cy + Math.sin(a) * 70, 4);
				g.endFill();
			}
			fill(g, 0x4DFF9A);
			for (i in 0...4)
				g.drawRect(cx - 30 + i * 18, cy + 30, 8, 30);
			g.endFill();
		}, 1, 12);
	}

	/** A customs checkpoint: two pylons, a scanner beam and a striped barrier across the lane. */
	public static function customsGate():FlxSprite
	{
		return sprite("customsgate", 480, 300, function(g)
		{
			line(g, 4, 0x3FD6C2, 0.8);
			for (i in 0...4)
				poly(g, [60, 50 + i * 54, 420, 50 + i * 54], false);
			g.lineStyle();
			for (i in 0...9)
			{
				fill(g, i % 2 == 0 ? 0xFFC21A : 0x211C2B);
				g.drawRect(60 + i * 40, 210, 40, 24);
				g.endFill();
			}
			for (x in [10.0, 410.0])
			{
				fill(g, 0x2B2440);
				line(g, 3, 0xF2F2F5);
				chamfer(g, x, 10, 60, 280, 12);
				g.endFill();
				g.lineStyle();
				fill(g, 0xE5343F);
				g.drawCircle(x + 30, 42, 12);
				g.endFill();
				fill(g, 0xD9B98A);
				g.drawRect(x + 12, 90, 36, 60);
				g.endFill();
				fill(g, 0x211C2B);
				for (i in 0...4)
					g.drawRect(x + 18, 100 + i * 11, 24, 4);
				g.endFill();
			}
		}, 1, 10);
	}

	public static function blackHole():FlxSprite
	{
		return sprite("blackhole", 480, 480, function(g)
		{
			var c = 240.0;
			for (i in 0...9)
			{
				var t = i / 8;
				line(g, 10 - t * 6, i % 2 == 0 ? 0xFF9A3C : 0xFFE45C, 0.25 + t * 0.6);
				g.drawEllipse(c - 230 + i * 12, c - 60 + i * 3, 460 - i * 24, 120 - i * 6);
			}
			g.lineStyle();
			radial(g, c, c, 150, 0xFF9A3C, 0xFF3C3C, 0.7, 0);
			fill(g, 0x000000);
			g.drawCircle(c, c, 96);
			g.endFill();
			line(g, 4, 0xFFE4A0);
			g.drawCircle(c, c, 98);
			line(g, 8, 0xFF9A3C, 0.9);
			g.moveTo(c - 228, c);
			g.curveTo(c, c + 36, c + 228, c);
		}, 1, 16);
	}

	public static function planet():FlxSprite
	{
		return sprite("planet", 640, 640, function(g)
		{
			var c = 320.0;
			radial(g, c, c, 320, 0x3CF0FF, 0x3CF0FF, 0.35, 0);
			var m = new Matrix();
			m.createGradientBox(560, 560, Math.PI / 3, c - 280, c - 280);
			g.beginGradientFill(GradientType.LINEAR, [0x6A3CFF, 0x1A1050], [1, 1], [0, 255], m);
			g.drawCircle(c, c, 270);
			g.endFill();
			line(g, 3, 0x9AE4FF, 0.6);
			for (i in 0...5)
				g.drawEllipse(c - 250 + i * 20, c - 120 + i * 46, 500 - i * 40, 30);
			line(g, 4, 0xEAF6FF);
			g.drawCircle(c, c, 270);
		}, 1, 16);
	}

	// ------------------------------------------------------------- portraits

	/** Path of a hand-made portrait for `who`, if one has been dropped into assets/portraits. */
	/** Which pixel-art portrait plays which character (files in assets/portraits). */
	public static var CAST:Map<String, String> = [
		"NOVA" => "181",
		"VEX" => "495",
		"RUST" => "207",
		"KADE" => "357",
		"PIP" => "6",
		"DISPATCH" => "119",
		"ZIB" => "12"
	];

	public static function portraitPath(who:String):Null<String>
	{
		var file = CAST.exists(who) ? CAST.get(who) : who.toLowerCase();
		var path = "assets/portraits/" + file + ".png";
		return openfl.utils.Assets.exists(path) ? path : null;
	}

	/**
	 * Dialogue portrait. Uses the pixel-art PNG from assets/portraits when present
	 * (shown at an exact 128 px so its pixels stay square), otherwise a drawn stand-in.
	 * The talking frame nudges the picture up two pixels for a speaking bob.
	 */
	public static function portrait(who:String, talk:Bool):FlxSprite
	{
		var accent = speakerColor(who);
		var path = portraitPath(who);
		if (path != null)
			return sprite('photo_${who}_${talk}_$accent', 140, 140, function(g)
			{
				var src = openfl.utils.Assets.getBitmapData(path);
				fill(g, 0x0B0814);
				line(g, 3, 0x211C2B);
				chamfer(g, 1.5, 1.5, 137, 137, 10);
				g.endFill();
				var k = 128 / src.width;
				var m = new Matrix();
				m.scale(k, k);
				m.translate(6, talk ? 4 : 6);
				g.lineStyle();
				g.beginBitmapFill(src, m, false, false);
				g.drawRect(6, 6, 128, 128);
				g.endFill();
				line(g, 4, accent);
				chamfer(g, 3, 3, 134, 134, 10);
			}, 0, 10, null, 0, true);
		return sprite('portrait_${who}_${talk}_$accent', 132, 132, function(g)
		{
			fill(g, 0x070C22, 0.95);
			line(g, 3, accent);
			chamfer(g, 2, 2, 128, 128, 18);
			g.endFill();
			switch (who)
			{
				case "NOVA":
					fill(g, 0x1A2A50);
					line(g, 3, 0x3CF0FF);
					poly(g, [24, 130, 30, 104, 102, 104, 108, 130], false);
					g.endFill();
					fill(g, 0xD8E0F0);
					line(g, 3, 0xFFFFFF);
					g.drawCircle(66, 64, 42);
					g.endFill();
					g.lineStyle();
					var m = new Matrix();
					m.createGradientBox(70, 34, Math.PI / 2, 31, 48);
					g.beginGradientFill(GradientType.LINEAR, [0xFFB03C, 0xFF5C2C], [1, 1], [0, 255], m);
					chamfer(g, 31, 48, 70, 34, 10);
					g.endFill();
					fill(g, 0xFFFFFF, 0.7);
					poly(g, [40, 52, 56, 52, 46, 62]);
					g.endFill();
					fill(g, 0x3CF0FF);
					g.drawRect(60, 100, 12, 6);
					g.endFill();
					if (talk)
					{
						fill(g, 0xFFF4C0);
						for (i in 0...4)
							g.drawRect(56 + i * 7, 72 - (i % 2) * 5, 4, 6 + (i % 2) * 5);
						g.endFill();
					}
				case "PIP":
					line(g, 3, 0x3CF0FF);
					poly(g, [66, 26, 66, 12], false);
					g.lineStyle();
					fill(g, 0xFF3CAC);
					g.drawCircle(66, 10, 5);
					g.endFill();
					fill(g, 0x14204A);
					line(g, 4, 0x3CF0FF);
					g.drawCircle(66, 68, 40);
					g.endFill();
					line(g, 2, 0x3CF0FF, 0.5);
					g.drawCircle(66, 68, 30);
					g.lineStyle();
					fill(g, 0x3CF0FF);
					g.drawCircle(66, 66, talk ? 18 : 14);
					g.endFill();
					fill(g, 0xFFFFFF);
					g.drawCircle(70, 62, talk ? 7 : 5);
					g.endFill();
					fill(g, 0x3CF0FF, 0.7);
					g.drawRect(20, 64, 8, 10);
					g.drawRect(104, 64, 8, 10);
					g.endFill();
				case "DISPATCH":
					fill(g, 0x0A3A24, 0.8);
					line(g, 3, 0x4DFF9A);
					g.drawCircle(66, 30, 16);
					g.drawEllipse(36, 30, 60, 74);
					g.endFill();
					poly(g, [30, 130, 40, 108, 92, 108, 102, 130], false);
					line(g, 3, 0x4DFF9A);
					g.drawCircle(52, 60, 4);
					g.drawCircle(80, 60, 4);
					if (talk)
					{
						fill(g, 0x4DFF9A);
						g.drawEllipse(58, 80, 16, 10);
						g.endFill();
					}
					else
						poly(g, [58, 84, 74, 84], false);
					line(g, 4, 0xEAF6FF);
					g.moveTo(32, 64);
					g.curveTo(30, 20, 66, 18);
					g.curveTo(102, 20, 100, 64);
					fill(g, 0xEAF6FF);
					g.drawRect(26, 58, 10, 16);
					g.endFill();
					line(g, 3, 0xEAF6FF);
					g.moveTo(32, 74);
					g.curveTo(34, 92, 56, 92);
					g.lineStyle();
					fill(g, 0x4DFF9A, 0.12);
					var y = 8;
					while (y < 128)
					{
						g.drawRect(4, y, 124, 2);
						y += 6;
					}
					g.endFill();
				case "RUST":
					fill(g, 0x2A1010);
					line(g, 3, 0xFF5C3C);
					chamfer(g, 30, 36, 72, 70, 12);
					g.endFill();
					fill(g, 0x101010);
					line(g, 3, 0xFFB03C);
					poly(g, [18, 40, 66, 8, 114, 40]);
					g.endFill();
					g.lineStyle();
					fill(g, 0xEAF6FF);
					g.drawCircle(66, 26, 6);
					g.endFill();
					fill(g, 0xFF3B5C);
					g.drawCircle(84, 62, 9);
					g.endFill();
					fill(g, 0x000000);
					line(g, 2, 0x606060);
					g.drawCircle(48, 62, 10);
					g.endFill();
					poly(g, [34, 50, 96, 74], false);
					line(g, 3, 0xFF5C3C);
					var jaw = talk ? 94 : 88;
					poly(g, [42, jaw, 90, jaw], false);
					for (i in 0...5)
						poly(g, [46 + i * 10, jaw - 6, 46 + i * 10, jaw + 6], false);
				case "VEX", "KADE":
					fill(g, who == "VEX" ? 0x3A1018 : 0x1C1A30);
					line(g, 3, accent);
					g.drawCircle(66, 56, 30);
					poly(g, [22, 130, 30, 98, 102, 98, 110, 130]);
					g.endFill();
					line(g, 3, accent);
					poly(g, [40, 36, 30, 12, 52, 30], false);
					poly(g, [92, 36, 102, 12, 80, 30], false);
					g.lineStyle();
					fill(g, 0xE5343F);
					g.drawRect(52, talk ? 52 : 54, 8, 4);
					g.drawRect(72, talk ? 52 : 54, 8, 4);
					g.endFill();
				case "ZIB":
					line(g, 3, 0xC8FF4D);
					poly(g, [50, 34, 40, 12], false);
					poly(g, [82, 34, 92, 12], false);
					g.lineStyle();
					fill(g, 0xFF3CAC);
					g.drawCircle(40, 12, 5);
					g.drawCircle(92, 12, 5);
					g.endFill();
					fill(g, 0x4A8A1C);
					line(g, 3, 0xC8FF4D);
					g.drawEllipse(22, 30, 88, 96);
					g.endFill();
					g.lineStyle();
					for (e in [[44, 62], [66, 52], [88, 62]])
					{
						fill(g, 0xFFFFFF);
						g.drawCircle(e[0], e[1], 10);
						g.endFill();
						fill(g, 0x101010);
						g.drawCircle(e[0] + 2, e[1] + 1, 5);
						g.endFill();
					}
					fill(g, 0x1A2A0A);
					if (talk)
						g.drawEllipse(54, 84, 24, 20);
					else
						g.drawEllipse(52, 88, 28, 8);
					g.endFill();
			}
		}, 1, 6);
	}

	/** Allies and the pilot are blue or green; whoever is hostile in this story is red. */
	public static function speakerColor(who:String):Int
	{
		if (Pilots.hostile(who))
			return G.RED;
		return switch (who)
		{
			case "NOVA": 0xFF5A7AE0;
			case "PIP": 0xFF3CF0FF;
			case "DISPATCH": 0xFF58D68D;
			case "ZIB": 0xFFC8FF4D;
			case "VEX": 0xFF3FD6C2;
			case "RUST": 0xFF9AF0E4;
			case "KADE": 0xFF2FA866;
			default: G.CYAN;
		}
	}
}
