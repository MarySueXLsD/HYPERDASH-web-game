package games;

import core.Art;
import core.Juice;
import core.Audio;
import core.G;
import flixel.FlxG;
import flixel.FlxSprite;

/** Drag each cable from the left panel to the socket of the same colour. */
class Rewire extends Micro
{
	static var COLORS:Array<Int> = [0xFFFF3B5C, 0xFF3CF0FF, 0xFFFFE45C, 0xFFFF3CAC];

	var left:Array<FlxSprite> = [];
	var right:Array<FlxSprite> = [];
	var wires:Array<FlxSprite> = [];
	var linked:Array<Bool> = [];
	var dragging:Int = -1;
	var count:Int;

	public function new(level:Int, speed:Float)
	{
		super(level, speed, [7, 8, 9][level]);
	}

	override function setup():Void
	{
		count = level + 2;
		var box = Art.panel(500, 640, 0x070C20, 0x3A4A80, 0.9, 24, 3);
		Art.center(box, G.W / 2, 500);
		add(box);
		var order = [for (i in 0...count) i];
		FlxG.random.shuffle(order);
		var gap = 520 / count;
		for (i in 0...count)
		{
			var y = 240 + gap * (i + 0.5);
			var w = Art.beam(8);
			w.color = COLORS[i];
			w.visible = false;
			wires.push(w);
			add(w);
			linked.push(false);
			var l = node(i, true);
			Art.center(l, 90, y);
			left.push(l);
			add(l);
		}
		for (i in 0...count)
		{
			var y = 240 + gap * (i + 0.5);
			var r = node(order[i], false);
			r.ID = order[i];
			Art.center(r, G.W - 90, y);
			right.push(r);
			add(r);
		}
	}

	function node(c:Int, plug:Bool):FlxSprite
	{
		var col = COLORS[c];
		var s = Art.sprite('wire_${c}_$plug', 70, 70, function(g)
		{
			Art.fill(g, 0x0A1030);
			Art.line(g, 4, col);
			if (plug)
				g.drawCircle(35, 35, 30);
			else
				Art.chamfer(g, 4, 4, 62, 62, 14);
			g.endFill();
			g.lineStyle();
			Art.fill(g, col);
			g.drawCircle(35, 35, plug ? 14 : 10);
			g.endFill();
		}, 1, 8);
		return s;
	}

	function socketOf(c:Int):FlxSprite
	{
		for (r in right)
			if (r.ID == c)
				return r;
		return null;
	}

	override function tick(elapsed:Float):Void
	{
		if (tapped())
		{
			for (i in 0...count)
				if (!linked[i] && near(left[i], 60))
				{
					dragging = i;
					wires[i].visible = true;
					Audio.sfx("click", 0.8);
				}
		}
		if (dragging >= 0)
		{
			var l = left[dragging];
			Art.setBeam(wires[dragging], Art.cx(l), Art.cy(l), px, py);
			if (FlxG.random.bool(40))
				fx.puff(px, py, COLORS[dragging], 0, 0, 0.4, 0.2);
			if (!FlxG.mouse.pressed || !live())
			{
				var hit:FlxSprite = null;
				for (r in right)
					if (near(r, 64))
						hit = r;
				if (hit != null && hit.ID == dragging && live())
				{
					linked[dragging] = true;
					Art.setBeam(wires[dragging], Art.cx(l), Art.cy(l), Art.cx(hit), Art.cy(hit));
					Audio.sfx("zap");
					Juice.small(Art.cx(hit), Art.cy(hit), COLORS[dragging]);
					fx.burst(Art.cx(hit), Art.cy(hit), COLORS[dragging], 16, 260, 0.4, 0.6);
					fx.shock(Art.cx(hit), Art.cy(hit), COLORS[dragging], 0.6);
					var all = true;
					for (k in linked)
						if (!k)
							all = false;
					if (all)
					{
						cheer(G.W / 2, 500);
						win();
					}
				}
				else
				{
					wires[dragging].visible = false;
					if (hit != null)
					{
						Audio.sfx("denied");
						fx.burst(px, py, G.RED, 10, 200, 0.3, 0.5);
					}
				}
				dragging = -1;
			}
		}
		for (i in 0...count)
			if (linked[i])
				wires[i].alpha = 0.75 + Math.random() * 0.25;
	}
}
