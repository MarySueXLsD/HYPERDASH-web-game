package core;

import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.Rectangle;

/**
 * "Waybill": a hand-made bitmap face. Squared letterforms with the top-left
 * corner of every round letter clipped, like the chamfered shipping labels,
 * and always bold: each stroke is thickened one pixel to the right (single
 * pixel gaps are kept open so M, W and m stay legible). Glyphs sit on a
 * 9-row cell (7 above the baseline, 2 for descenders) and are drawn as exact
 * squares at any whole-number scale.
 */
class PixelFont
{
	public static inline var ROWS:Int = 9;
	public static inline var LINE:Int = 11;

	static var GLYPHS:Map<String, Array<String>> = [
		"A" => [".####", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
		"B" => ["####.", "#...#", "#...#", "#####", "#...#", "#...#", "#####"],
		"C" => [".####", "#....", "#....", "#....", "#....", "#....", "#####"],
		"D" => ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "#####"],
		"E" => ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
		"F" => ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
		"G" => [".####", "#....", "#....", "#..##", "#...#", "#...#", "#####"],
		"H" => ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
		"I" => ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
		"J" => ["....#", "....#", "....#", "....#", "#...#", "#...#", "#####"],
		"K" => ["#...#", "#..#.", "#.#..", "###..", "#..#.", "#...#", "#...#"],
		"L" => ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
		"M" => ["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#", "#...#"],
		"N" => ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
		"O" => [".####", "#...#", "#...#", "#...#", "#...#", "#...#", "#####"],
		"P" => ["####.", "#...#", "#...#", "#####", "#....", "#....", "#...."],
		"Q" => [".####", "#...#", "#...#", "#...#", "#...#", "#..#.", "###.#"],
		"R" => ["####.", "#...#", "#...#", "####.", "#..#.", "#...#", "#...#"],
		"S" => [".####", "#....", "#....", "#####", "....#", "....#", "#####"],
		"T" => ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
		"U" => ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", "#####"],
		"V" => ["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
		"W" => ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
		"X" => ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
		"Y" => ["#...#", "#...#", "#...#", ".###.", "..#..", "..#..", "..#.."],
		"Z" => ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
		"a" => [".....", ".....", "####.", "....#", ".####", "#...#", "#####"],
		"b" => ["#....", "#....", "####.", "#...#", "#...#", "#...#", "#####"],
		"c" => [".....", ".....", ".####", "#....", "#....", "#....", "#####"],
		"d" => ["....#", "....#", ".####", "#...#", "#...#", "#...#", "#####"],
		"e" => [".....", ".....", ".####", "#...#", "#####", "#....", "#####"],
		"f" => [".###", "#...", "###.", "#...", "#...", "#...", "#..."],
		"g" => [".....", ".....", ".####", "#...#", "#...#", "#...#", "#####", "....#", "####."],
		"h" => ["#....", "#....", "####.", "#...#", "#...#", "#...#", "#...#"],
		"i" => ["#", ".", "#", "#", "#", "#", "#"],
		"j" => ["..#", "...", "..#", "..#", "..#", "..#", "..#", "..#", "##."],
		"k" => ["#...", "#...", "#..#", "#.#.", "##..", "#.#.", "#..#"],
		"l" => ["#", "#", "#", "#", "#", "#", "#"],
		"m" => [".....", ".....", "####.", "#.#.#", "#.#.#", "#.#.#", "#.#.#"],
		"n" => [".....", ".....", "####.", "#...#", "#...#", "#...#", "#...#"],
		"o" => [".....", ".....", ".####", "#...#", "#...#", "#...#", "#####"],
		"p" => [".....", ".....", "####.", "#...#", "#...#", "#...#", "#####", "#....", "#...."],
		"q" => [".....", ".....", ".####", "#...#", "#...#", "#...#", "#####", "....#", "....#"],
		"r" => ["....", "....", ".###", "#...", "#...", "#...", "#..."],
		"s" => [".....", ".....", ".####", "#....", "#####", "....#", "#####"],
		"t" => ["#..", "#..", "###", "#..", "#..", "#..", ".##"],
		"u" => [".....", ".....", "#...#", "#...#", "#...#", "#...#", "#####"],
		"v" => [".....", ".....", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
		"w" => [".....", ".....", "#...#", "#...#", "#.#.#", "#.#.#", "#####"],
		"x" => [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
		"y" => [".....", ".....", "#...#", "#...#", "#...#", "#...#", "#####", "....#", "####."],
		"z" => [".....", ".....", "#####", "...#.", "..#..", ".#...", "#####"],
		"0" => [".####", "#...#", "#..##", "#.#.#", "##..#", "#...#", "#####"],
		"1" => ["##.", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
		"2" => ["####.", "....#", "....#", ".###.", "#....", "#....", "#####"],
		"3" => ["####.", "....#", "....#", ".###.", "....#", "....#", "#####"],
		"4" => ["#...#", "#...#", "#...#", "#####", "....#", "....#", "....#"],
		"5" => ["#####", "#....", "#....", "####.", "....#", "....#", "#####"],
		"6" => [".####", "#....", "#....", "#####", "#...#", "#...#", "#####"],
		"7" => ["#####", "....#", "...#.", "..#..", "..#..", "..#..", "..#.."],
		"8" => [".####", "#...#", "#...#", "#####", "#...#", "#...#", "#####"],
		"9" => [".####", "#...#", "#...#", "#####", "....#", "....#", "#####"],
		"." => [".", ".", ".", ".", ".", ".", "#"],
		"," => ["..", "..", "..", "..", "..", ".#", ".#", "#."],
		"!" => ["#", "#", "#", "#", "#", ".", "#"],
		"?" => [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
		"'" => ["#", "#", ".", ".", ".", ".", "."],
		"\"" => ["#.#", "#.#", "...", "...", "...", "...", "..."],
		":" => [".", ".", "#", ".", ".", "#", "."],
		";" => ["..", "..", ".#", "..", "..", ".#", ".#", "#."],
		"-" => ["....", "....", "....", "####", "....", "....", "...."],
		"+" => [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
		"/" => ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
		"(" => [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
		")" => ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
		"%" => ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
		"#" => [".#.#.", ".#.#.", "#####", ".#.#.", "#####", ".#.#.", ".#.#."],
		"&" => [".##..", "#..#.", "#.#..", ".#...", "#.#.#", "#..#.", ".##.#"],
		"*" => [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."],
		"=" => [".....", ".....", "#####", ".....", "#####", ".....", "....."],
		"<" => ["...#", "..#.", ".#..", "#...", ".#..", "..#.", "...#"],
		">" => ["#...", ".#..", "..#.", "...#", "..#.", ".#..", "#..."],
		"_" => [".....", ".....", ".....", ".....", ".....", ".....", "#####"],
		"×" => [".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "....."],
		"★" => ["..#..", "..#..", "#####", ".###.", ".#.#.", "#...#", "....."]
	];

	static inline var SPACE:Int = 3;

	static inline function lit(row:String, c:Int):Bool
	{
		return c < row.length && row.charCodeAt(c) == "#".code;
	}

	static function glyph(ch:String):Array<String>
	{
		var g = GLYPHS.get(ch);
		return g != null ? g : GLYPHS.get("?");
	}

	static function clean(s:String):String
	{
		return s.split("…").join("...").split("—").join("-").split("–").join("-").split("’").join("'");
	}

	/** Width of one line in font pixels. */
	public static function lineWidth(line:String):Int
	{
		line = clean(line);
		var w = 0;
		for (i in 0...line.length)
		{
			var ch = line.charAt(i);
			w += ch == " " ? SPACE : glyph(ch)[0].length + 1;
			if (i < line.length - 1)
				w += 1;
		}
		return w;
	}

	/** Splits text into lines no wider than `maxW` screen pixels at `px` screen pixels per font pixel. */
	public static function wrap(text:String, maxW:Float, px:Int):Array<String>
	{
		var out:Array<String> = [];
		for (para in clean(text).split("\n"))
		{
			if (maxW <= 0)
			{
				out.push(para);
				continue;
			}
			var line = "";
			for (word in para.split(" "))
			{
				var trial = line == "" ? word : line + " " + word;
				if (line != "" && lineWidth(trial) * px > maxW)
				{
					out.push(line);
					line = word;
				}
				else
					line = trial;
			}
			out.push(line);
		}
		return out;
	}

	/** Italic shear: the top rows shift right by up to two font pixels. */
	static inline function shear(row:Int, italic:Bool):Int
	{
		return italic ? Std.int((6 - Math.min(row, 6)) / 3) : 0;
	}

	/**
	 * Visits every lit font pixel of `lines`. `limit` reveals only the first
	 * `limit` characters (for typewriter text); -1 shows everything.
	 */
	static function each(lines:Array<String>, px:Int, italic:Bool, align:String, boxW:Float, limit:Int, fn:Float->Float->Void):Void
	{
		var shown = 0;
		for (li in 0...lines.length)
		{
			var line = lines[li];
			var lw = lineWidth(line) * px;
			var ox = align == "center" ? (boxW - lw) / 2 : (align == "right" ? boxW - lw : 0);
			ox = Math.round(ox / px) * px;
			var cx = ox;
			var oy = li * LINE * px;
			for (i in 0...line.length)
			{
				if (limit >= 0 && shown >= limit)
					return;
				shown++;
				var ch = line.charAt(i);
				if (ch == " ")
				{
					cx += (SPACE + 1) * px;
					continue;
				}
				var g = glyph(ch);
				for (r in 0...g.length)
				{
					var row = g[r];
					var sh = shear(r, italic) * px;
					for (c in 0...row.length)
						if (lit(row, c))
						{
							fn(cx + c * px + sh, oy + r * px);
							// Bold: thicken to the right unless that would close a one-pixel gap.
							if (!lit(row, c + 1) && !lit(row, c + 2))
								fn(cx + (c + 1) * px + sh, oy + r * px);
						}
				}
				cx += (g[0].length + 2) * px;
			}
			shown++; // the line break counts as a character
		}
	}

	public static function measure(text:String, px:Int, maxW:Float = 0):{w:Int, h:Int, lines:Array<String>}
	{
		var lines = wrap(text, maxW, px);
		var w = 0;
		for (l in lines)
			w = Std.int(Math.max(w, lineWidth(l) * px));
		var h = ((lines.length - 1) * LINE + 7) * px;
		for (l in lines)
			if (l.indexOf("g") >= 0 || l.indexOf("j") >= 0 || l.indexOf("p") >= 0 || l.indexOf("q") >= 0 || l.indexOf("y") >= 0
				|| l.indexOf(",") >= 0 || l.indexOf(";") >= 0)
			{
				h = (lines.length * LINE - 2) * px;
				break;
			}
		return {w: w + 2 * px, h: h, lines: lines};
	}

	/** Draws text as filled squares into a Graphics (used for baked sprites and stamps). */
	public static function drawGraphics(g:Graphics, text:String, x:Float, y:Float, px:Int, color:Int, italic:Bool = false, align:String = "center", boxW:Float = -1):Void
	{
		var m = measure(text, px);
		x = Math.round(x);
		y = Math.round(y);
		g.lineStyle();
		g.beginFill(color & 0xFFFFFF, 1);
		each(m.lines, px, italic, align, boxW < 0 ? m.w : boxW, -1, function(fx, fy) g.drawRect(x + fx, y + fy, px, px));
		g.endFill();
	}

	static var cell = new Rectangle();

	/** Draws text straight into a bitmap (used by PixelText for changing strings). */
	public static function drawBitmap(b:BitmapData, lines:Array<String>, x:Float, y:Float, px:Int, color:Int, italic:Bool, align:String, boxW:Float, limit:Int):Void
	{
		cell.width = cell.height = px;
		each(lines, px, italic, align, boxW, limit, function(fx, fy)
		{
			cell.x = x + fx;
			cell.y = y + fy;
			b.fillRect(cell, color);
		});
	}

	/** Screen pixels per font pixel for a requested cap height, snapped to the art grid. */
	public static function pxFor(size:Float):Int
	{
		return Std.int(Math.max(2, Math.round(size / 7)));
	}
}
