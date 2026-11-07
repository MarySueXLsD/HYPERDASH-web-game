package states;

import core.Audio;
import core.G;
import core.Run;
import core.Ui;
import core.VecFont;
import games.Catalog;

/** Pick any mini game and play it on a loop as it speeds up. */
class TrainingState extends BaseState
{
	override function build():Void
	{
		Audio.music("title");
		stars.rate = 0.3;
		stars.stretch = 0.1;
		add(sparks);

		var h = VecFont.sprite("TRAINING", 44, G.ORANGE, 0.22, 0, 8);
		h.setPosition(28, 44);
		add(h);
		Ui.slam(h, 0.1, 1.8, 0.35);
		var sub = Ui.text(28, 104, G.W - 56, "Every clear speeds it up.", 16, 0xFFC9C2DE, "left");
		add(sub);

		var cols = 3;
		var tw = 164;
		var th = 66;
		var gx = 10;
		var gy = 6;
		var x0 = (G.W - (cols * tw + (cols - 1) * gx)) / 2;
		var y0 = 148.0;
		var i = 0;
		var items:Array<Button> = [];
		for (info in Catalog.ALL)
		{
			var cx = x0 + (i % cols) * (tw + gx);
			var cy = y0 + Std.int(i / cols) * (th + gy);
			var label = info.verb.split("!").join("");
			if (label.length > 10 && label.indexOf(" ") > 0)
				label = label.substr(0, label.lastIndexOf(" ")) + "\n" + label.substr(label.lastIndexOf(" ") + 1);
			var boss = info.id == Catalog.BOSS;
			var id = info.id;
			var b = new Button(cx, cy, tw, th, label, boss, function() play(id), 13);
			add(b);
			items.push(b);
			Ui.fadeIn(b, 0.15 + i * 0.015, 0.3, 30);
			i++;
		}

		var back = new Button(G.W / 2 - 130, G.H - 104, 260, 66, "BACK", false, function() go(TitleState.new), 24);
		add(back);
		items.push(back);
		add(new Nav(items, cols));
	}

	function play(id:String):Void
	{
		G.run = new Run(TRAINING, id);
		Audio.sfx("start");
		go(RunState.new);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (flixel.FlxG.keys.justPressed.ESCAPE)
			go(TitleState.new);
	}
}
