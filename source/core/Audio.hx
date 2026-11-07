package core;

#if js
import js.Browser;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.html.audio.GainNode;
#end

/**
 * Every sound in the game is synthesised at runtime with WebAudio:
 * a small step sequencer for the music and one-shot recipes for effects.
 */
class Audio
{
	#if js
	static var ctx:AudioContext;
	static var master:GainNode;
	static var musicBus:GainNode;
	static var sfxBus:GainNode;
	static var noise:AudioBuffer;
	static var timer:Int = -1;
	#end

	static var song:String = "";
	static var tempo:Float = 1;
	static var step:Int = 0;
	static var nextTime:Float = 0;
	static var duck:Float = 1;

	public static function unlock():Void
	{
		#if js
		if (ctx == null)
		{
			var w:Dynamic = Browser.window;
			var ctor:Dynamic = w.AudioContext != null ? w.AudioContext : w.webkitAudioContext;
			if (ctor == null)
				return;
			ctx = js.Syntax.construct(ctor);
			var comp = ctx.createDynamicsCompressor();
			comp.threshold.value = -14;
			comp.ratio.value = 4;
			comp.connect(ctx.destination);
			master = ctx.createGain();
			master.gain.value = 0.8;
			master.connect(comp);
			musicBus = ctx.createGain();
			musicBus.gain.value = G.musicOn ? 0.55 : 0;
			musicBus.connect(master);
			sfxBus = ctx.createGain();
			sfxBus.gain.value = G.sfxOn ? 0.9 : 0;
			sfxBus.connect(master);
			var len = Std.int(ctx.sampleRate);
			noise = ctx.createBuffer(1, len, ctx.sampleRate);
			var data = noise.getChannelData(0);
			for (i in 0...len)
				data[i] = Math.random() * 2 - 1;
			timer = Browser.window.setInterval(schedule, 25);
		}
		if (untyped ctx.state == "suspended")
			ctx.resume();
		#end
	}

	public static function suspend(on:Bool):Void
	{
		#if js
		if (ctx == null)
			return;
		if (on)
			ctx.suspend();
		else
			ctx.resume();
		#end
	}

	public static function applySettings():Void
	{
		#if js
		if (ctx == null)
			return;
		musicBus.gain.setTargetAtTime(G.musicOn ? 0.55 * duck : 0, ctx.currentTime, 0.05);
		sfxBus.gain.setTargetAtTime(G.sfxOn ? 0.9 : 0, ctx.currentTime, 0.05);
		#end
	}

	/** Lowers the music, used by the pause menu. */
	public static function setDuck(v:Float):Void
	{
		duck = v;
		applySettings();
	}

	public static function music(name:String):Void
	{
		if (name == song)
			return;
		song = name;
		step = 0;
		#if js
		if (ctx != null)
			nextTime = ctx.currentTime + 0.08;
		#end
	}

	public static function setTempo(mult:Float):Void
	{
		tempo = mult;
	}

	// ------------------------------------------------------------------ music

	static var PROG_MAIN = [57, 53, 48, 55];
	static var PROG_DARK = [57, 53, 52, 52];
	static var PROG_WIN = [48, 55, 57, 53];
	static var MINOR = [0, 3, 7, 12];
	static var MAJOR = [0, 4, 7, 12];

	#if js
	static function schedule():Void
	{
		if (ctx == null || song == "" || untyped ctx.state != "running")
			return;
		var now = ctx.currentTime;
		if (nextTime < now - 0.2)
			nextTime = now + 0.02;
		while (nextTime < now + 0.12)
		{
			playStep(step, nextTime);
			var bpm = songBpm() * tempo;
			nextTime += 60 / bpm / 4;
			step++;
		}
	}

	static function songBpm():Float
	{
		return switch (song)
		{
			case "title": 108;
			case "cut": 96;
			case "over": 80;
			case "win": 112;
			default: G.BPM;
		}
	}

	static function playStep(s:Int, t:Float):Void
	{
		var bar = Std.int(s / 16);
		var st = s % 16;
		var prog = switch (song)
		{
			case "boss", "over": PROG_DARK;
			case "win": PROG_WIN;
			default: PROG_MAIN;
		}
		var root = prog[bar % 4];
		var minor = (root == 57 || root == 52) && song != "win";
		var chord = minor ? MINOR : MAJOR;
		if (song == "win")
			chord = root == 57 ? MINOR : MAJOR;

		switch (song)
		{
			case "title":
				if (st == 0)
					pad(root, chord, t, 60 / 108 * 4, 0.05);
				if (st % 2 == 0)
					pluck(root + 12 + chord[[0, 1, 2, 3, 2, 1, 0, 2][(st >> 1) % 8]], t, 0.035, 0.18);
				if (st == 0 || st == 10)
					kick(t, 0.35);
				if (st % 4 == 2)
					hat(t, 0.04);
				if (st % 4 == 0)
					bass(root - 12, t, 0.3, 0.12);
			case "cut":
				if (st == 0)
					pad(root, chord, t, 60 / 96 * 4, 0.06);
				if (st % 4 == 0)
					pluck(root + 24 + chord[(st >> 2) % 3], t, 0.02, 0.3);
			case "over":
				if (st == 0)
					pad(root - 12, chord, t, 60 / 80 * 4, 0.07);
				if (st == 0 || st == 8)
					pluck(root + 12 + chord[(bar + (st >> 3)) % 3], t, 0.03, 0.6);
			case "win":
				if (st == 0)
					pad(root, chord, t, 60 / 112 * 4, 0.05);
				if (st % 2 == 0)
					pluck(root + 12 + chord[[0, 1, 2, 3, 2, 3, 1, 2][(st >> 1) % 8]], t, 0.04, 0.16);
				if (st % 4 == 0)
					kick(t, 0.45);
				if (st % 8 == 4)
					snare(t, 0.12);
				if (st % 2 == 1)
					hat(t, 0.03);
				if (st % 2 == 0)
					bass(root - 12 + (st % 4 == 2 ? 12 : 0), t, 0.18, 0.12);
			default: // "run" and "boss"
				var boss = song == "boss";
				if (st == 0)
					pad(root, chord, t, 60 / G.BPM / tempo * 4, 0.035);
				if (st % 4 == 0)
					kick(t, 0.6);
				if (boss && st == 14)
					kick(t, 0.4);
				if (st % 8 == 4)
					snare(t, 0.2);
				if (st % 2 == 1 || boss)
					hat(t, st % 4 == 2 ? 0.05 : 0.025);
				var b = root - 12 + ((st % 4 == 2) ? 12 : 0);
				bass(b, t, 0.11, boss ? 0.15 : 0.12);
				var arp = [0, 1, 2, 3, 2, 1, 2, 3];
				if (boss || st % 2 == 0)
					pluck(root + 12 + chord[arp[st % 8]], t, boss ? 0.03 : 0.028, 0.12);
		}
	}

	// -------------------------------------------------------- synth voices

	static inline function mtof(n:Float):Float
	{
		return 440 * Math.pow(2, (n - 69) / 12);
	}

	static function env(g:GainNode, t:Float, peak:Float, attack:Float, decay:Float):Void
	{
		g.gain.setValueAtTime(0.0001, t);
		g.gain.linearRampToValueAtTime(peak, t + attack);
		g.gain.exponentialRampToValueAtTime(0.0001, t + attack + decay);
	}

	static function osc(type:String, freq:Float, t:Float, dur:Float, peak:Float, out:AudioNode, attack:Float = 0.005, ?slideTo:Float, detune:Float = 0):Void
	{
		var o = ctx.createOscillator();
		untyped o.type = type;
		o.frequency.setValueAtTime(freq, t);
		if (slideTo != null)
			o.frequency.exponentialRampToValueAtTime(Math.max(1, slideTo), t + dur);
		o.detune.value = detune;
		var g = ctx.createGain();
		env(g, t, peak, attack, dur);
		o.connect(g);
		g.connect(out);
		o.start(t);
		o.stop(t + attack + dur + 0.05);
	}

	static function noiseBurst(t:Float, dur:Float, peak:Float, filter:String, freq:Float, out:AudioNode, q:Float = 1, ?sweepTo:Float):Void
	{
		var src = ctx.createBufferSource();
		src.buffer = noise;
		var f = ctx.createBiquadFilter();
		untyped f.type = filter;
		f.frequency.setValueAtTime(freq, t);
		if (sweepTo != null)
			f.frequency.exponentialRampToValueAtTime(sweepTo, t + dur);
		f.Q.value = q;
		var g = ctx.createGain();
		env(g, t, peak, 0.004, dur);
		src.connect(f);
		f.connect(g);
		g.connect(out);
		src.start(t, Math.random() * 0.5);
		src.stop(t + dur + 0.05);
	}

	static function kick(t:Float, v:Float):Void
	{
		osc("sine", 150, t, 0.22, v, musicBus, 0.002, 38);
	}

	static function snare(t:Float, v:Float):Void
	{
		noiseBurst(t, 0.16, v, "bandpass", 1900, musicBus, 0.8);
		osc("triangle", 190, t, 0.08, v * 0.6, musicBus, 0.002, 120);
	}

	static function hat(t:Float, v:Float):Void
	{
		noiseBurst(t, 0.035, v, "highpass", 8000, musicBus);
	}

	static function bass(n:Float, t:Float, dur:Float, v:Float):Void
	{
		var o = ctx.createOscillator();
		untyped o.type = "sawtooth";
		o.frequency.value = mtof(n);
		var f = ctx.createBiquadFilter();
		untyped f.type = "lowpass";
		f.frequency.setValueAtTime(1400, t);
		f.frequency.exponentialRampToValueAtTime(180, t + dur);
		f.Q.value = 6;
		var g = ctx.createGain();
		env(g, t, v, 0.004, dur);
		o.connect(f);
		f.connect(g);
		g.connect(musicBus);
		o.start(t);
		o.stop(t + dur + 0.05);
	}

	static function pluck(n:Float, t:Float, v:Float, dur:Float):Void
	{
		osc("square", mtof(n), t, dur, v, musicBus, 0.003);
		osc("sawtooth", mtof(n), t, dur * 0.7, v * 0.5, musicBus, 0.003, null, 9);
	}

	static function pad(root:Int, chord:Array<Int>, t:Float, dur:Float, v:Float):Void
	{
		var f = ctx.createBiquadFilter();
		untyped f.type = "lowpass";
		f.frequency.value = 900;
		var g = ctx.createGain();
		g.gain.setValueAtTime(0.0001, t);
		g.gain.linearRampToValueAtTime(v, t + dur * 0.3);
		g.gain.linearRampToValueAtTime(0.0001, t + dur * 1.05);
		f.connect(g);
		g.connect(musicBus);
		for (i in 0...3)
		{
			for (d in [-8, 8])
			{
				var o = ctx.createOscillator();
				untyped o.type = "sawtooth";
				o.frequency.value = mtof(root + chord[i]);
				o.detune.value = d;
				o.connect(f);
				o.start(t);
				o.stop(t + dur * 1.1);
			}
		}
	}
	#end

	// ---------------------------------------------------------------- effects

	public static function sfx(name:String, pitch:Float = 1):Void
	{
		#if js
		if (ctx == null || !G.sfxOn)
			return;
		var t = ctx.currentTime + 0.005;
		var o = sfxBus;
		switch (name)
		{
			case "click":
				osc("square", 880 * pitch, t, 0.05, 0.12, o, 0.002, 1320 * pitch);
			case "hover":
				osc("sine", 1400, t, 0.03, 0.05, o);
			case "back":
				osc("square", 700, t, 0.06, 0.1, o, 0.002, 420);
			case "start":
				for (i in 0...4)
					osc("square", mtof(69 + [0, 4, 7, 12][i]), t + i * 0.06, 0.12, 0.1, o);
				noiseBurst(t, 0.5, 0.15, "bandpass", 400, o, 1, 6000);
			case "type":
				osc("square", 1100 + Math.random() * 300, t, 0.018, 0.035, o);
			case "prompt":
				noiseBurst(t, 0.3, 0.25, "bandpass", 300, o, 1.2, 5000);
				for (n in [69, 76, 81])
					osc("sawtooth", mtof(n), t + 0.02, 0.25, 0.06, o, 0.005);
			case "win":
				for (i in 0...4)
					osc("square", mtof(72 + [0, 4, 7, 12][i]) * pitch, t + i * 0.055, 0.12, 0.1, o);
				osc("sine", 2093, t + 0.22, 0.3, 0.06, o);
			case "lose":
				osc("sawtooth", 260, t, 0.4, 0.18, o, 0.005, 60);
				osc("square", 130, t, 0.3, 0.1, o, 0.005, 50);
				noiseBurst(t, 0.3, 0.2, "lowpass", 1200, o);
			case "tick":
				osc("square", 1600 * pitch, t, 0.03, 0.06, o);
			case "laser":
				osc("square", 1600 * pitch, t, 0.12, 0.08, o, 0.002, 220);
				osc("sawtooth", 800 * pitch, t, 0.1, 0.05, o, 0.002, 160);
			case "boom":
				noiseBurst(t, 0.6, 0.45, "lowpass", 2400, o, 1, 80);
				osc("sine", 110, t, 0.5, 0.4, o, 0.002, 30);
			case "pop":
				osc("sine", 520 * pitch, t, 0.08, 0.18, o, 0.002, 1300 * pitch);
			case "coin":
				osc("square", 988 * pitch, t, 0.06, 0.08, o);
				osc("square", 1319 * pitch, t + 0.06, 0.14, 0.08, o);
			case "thrust":
				noiseBurst(t, 0.12, 0.08 * pitch, "lowpass", 900, o);
			case "speedup":
				osc("sawtooth", 140, t, 1.1, 0.12, o, 0.05, 1800);
				osc("square", 70, t, 1.1, 0.06, o, 0.05, 900);
				noiseBurst(t, 1.1, 0.2, "bandpass", 300, o, 2, 8000);
			case "warp":
				noiseBurst(t, 1.4, 0.35, "bandpass", 120, o, 1.5, 9000);
				osc("sine", 60, t, 1.4, 0.3, o, 0.2, 400);
			case "lock":
				osc("square", 1760, t, 0.04, 0.07, o);
			case "locked":
				for (i in 0...3)
					osc("square", 2093, t + i * 0.07, 0.05, 0.08, o);
			case "hit":
				noiseBurst(t, 0.12, 0.3, "lowpass", 3000, o);
				osc("square", 140, t, 0.1, 0.15, o, 0.002, 60);
			case "swipe":
				noiseBurst(t, 0.15, 0.18, "bandpass", 800, o, 2, 5000);
			case "dock":
				osc("triangle", 220, t, 0.25, 0.25, o, 0.002, 180);
				osc("square", 660, t, 0.08, 0.06, o);
				noiseBurst(t, 0.1, 0.2, "highpass", 2000, o);
			case "denied":
				osc("square", 220, t, 0.08, 0.12, o);
				osc("square", 180, t + 0.1, 0.12, 0.12, o);
			case "zap":
				osc("sawtooth", 2400 * pitch, t, 0.06, 0.06, o, 0.001, 600);
				noiseBurst(t, 0.06, 0.12, "highpass", 4000, o);
			case "charge":
				osc("triangle", 300 * pitch, t, 0.05, 0.05, o);
			case "slam":
				osc("sine", 90, t, 0.35, 0.5, o, 0.002, 40);
				noiseBurst(t, 0.25, 0.3, "lowpass", 4000, o, 1, 200);
			case "alarm":
				for (i in 0...2)
				{
					osc("square", 880, t + i * 0.3, 0.14, 0.09, o, 0.01, 660);
				}
			case "flip":
				osc("triangle", 400 * pitch, t, 0.09, 0.15, o, 0.002, 900 * pitch);
			case "beep":
				osc("sine", 880 * pitch, t, 0.08, 0.1, o);
		}
		#end
	}
}
