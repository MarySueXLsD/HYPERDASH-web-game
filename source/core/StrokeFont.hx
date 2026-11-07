package core;

import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.JointStyle;

/** Stencil stroke lettering on a 4×6 grid, used for rubber-stamp badges such as DELIVERED. */
class StrokeFont
{
	static inline var GW:Float = 4;
	static inline var GH:Float = 6;
	static inline var ADV:Float = 5.4;

	static var O:Array<Float> = [1, 0, 3, 0, 4, 1, 4, 5, 3, 6, 1, 6, 0, 5, 0, 1, 1, 0];

	static var GLYPHS:Map<String, Array<Array<Float>>> = [
		"A" => [[0, 6, 0, 1, 1, 0, 3, 0, 4, 1, 4, 6], [0, 3.5, 4, 3.5]],
		"B" => [[0, 0, 3, 0, 4, 1, 4, 2, 3, 3, 0, 3], [3, 3, 4, 4, 4, 5, 3, 6, 0, 6, 0, 0]],
		"C" => [[4, 0, 1, 0, 0, 1, 0, 5, 1, 6, 4, 6]],
		"D" => [[0, 0, 3, 0, 4, 1, 4, 5, 3, 6, 0, 6, 0, 0]],
		"E" => [[4, 0, 0, 0, 0, 6, 4, 6], [0, 3, 3, 3]],
		"F" => [[4, 0, 0, 0, 0, 6], [0, 3, 3, 3]],
		"G" => [[4, 0, 1, 0, 0, 1, 0, 5, 1, 6, 4, 6, 4, 3.5, 2.5, 3.5]],
		"H" => [[0, 0, 0, 6], [4, 0, 4, 6], [0, 3, 4, 3]],
		"I" => [[1, 0, 3, 0], [2, 0, 2, 6], [1, 6, 3, 6]],
		"J" => [[4, 0, 4, 5, 3, 6, 1, 6, 0, 5]],
		"K" => [[0, 0, 0, 6], [4, 0, 1, 3, 0, 3], [1, 3, 4, 6]],
		"L" => [[0, 0, 0, 6, 4, 6]],
		"M" => [[0, 6, 0, 0, 2, 2.5, 4, 0, 4, 6]],
		"N" => [[0, 6, 0, 0, 4, 6, 4, 0]],
		"O" => [O],
		"P" => [[0, 6, 0, 0, 3, 0, 4, 1, 4, 2, 3, 3, 0, 3]],
		"R" => [[0, 6, 0, 0, 3, 0, 4, 1, 4, 2, 3, 3, 0, 3], [2, 3, 4, 6]],
		"S" => [[4, 0, 1, 0, 0, 1, 0, 2, 1, 3, 3, 3, 4, 4, 4, 5, 3, 6, 0, 6]],
		"T" => [[0, 0, 4, 0], [2, 0, 2, 6]],
		"U" => [[0, 0, 0, 5, 1, 6, 3, 6, 4, 5, 4, 0]],
		"V" => [[0, 0, 2, 6, 4, 0]],
		"W" => [[0, 0, 1, 6, 2, 3, 3, 6, 4, 0]],
		"X" => [[0, 0, 4, 6], [4, 0, 0, 6]],
		"Y" => [[0, 0, 2, 3, 4, 0], [2, 3, 2, 6]],
		"Z" => [[0, 0, 4, 0, 0, 6, 4, 6]],
		"!" => [[2, 0, 2, 4.2], [2, 5.7, 2, 6]]
	];

	public static function width(text:String, size:Float, thick:Float):Int
	{
		var unit = size / GH;
		return Std.int(Math.ceil(((text.length - 1) * ADV + GW) * unit + thick * 2));
	}

	public static function draw(g:Graphics, text:String, size:Float, color:Int, thick:Float, x:Float, y:Float):Void
	{
		var unit = size / GH;
		g.lineStyle(thick, color & 0xFFFFFF, 1, false, null, CapsStyle.SQUARE, JointStyle.MITER, 3);
		for (ci in 0...text.length)
		{
			var strokes = GLYPHS.get(text.charAt(ci).toUpperCase());
			if (strokes == null)
				continue;
			var gx = x + thick + ci * ADV * unit;
			for (s in strokes)
			{
				var i = 0;
				while (i < s.length)
				{
					var px = gx + s[i] * unit;
					var py = y + thick + s[i + 1] * unit;
					if (i == 0)
						g.moveTo(px, py);
					else
						g.lineTo(px, py);
					i += 2;
				}
			}
		}
	}
}
