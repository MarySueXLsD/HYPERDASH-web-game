package fx;

import core.Art;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BlendMode;

class Spark extends FlxSprite
{
	public var life:Float = 0;
	public var total:Float = 1;
	public var grow:Float = 0;
	public var startScale:Float = 1;
	public var stretchy:Bool = false;

	public function new()
	{
		super();
		blend = BlendMode.ADD;
		antialiasing = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
		{
			kill();
			return;
		}
		var t = life / total;
		alpha = t;
		var s = startScale * (1 + grow * (1 - t));
		scale.set(s, s);
		if (stretchy)
			angle = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
	}
}

/** Additive particle pool shared by a state: bursts, sparks and shockwave rings. */
class Sparks extends FlxTypedGroup<Spark>
{
	public function new()
	{
		super(400);
	}

	function get():Spark
	{
		var s = recycle(Spark);
		s.velocity.set(0, 0);
		s.acceleration.set(0, 0);
		s.drag.set(0, 0);
		s.angle = 0;
		s.angularVelocity = 0;
		s.grow = 0;
		s.stretchy = false;
		return s;
	}

	public function burst(x:Float, y:Float, color:Int, count:Int = 16, speed:Float = 320, life:Float = 0.5, size:Float = 0.6):Void
	{
		for (i in 0...count)
		{
			var s = get();
			s.loadGraphic(i % 3 == 0 ? Art.dot() : Art.spark());
			s.stretchy = i % 3 != 0;
			s.color = color;
			s.setPosition(x - s.width / 2, y - s.height / 2);
			var a = FlxG.random.float(0, Math.PI * 2);
			var v = FlxG.random.float(0.3, 1) * speed;
			s.velocity.set(Math.cos(a) * v, Math.sin(a) * v);
			s.drag.set(speed * 1.2, speed * 1.2);
			s.total = s.life = FlxG.random.float(0.6, 1) * life;
			s.startScale = FlxG.random.float(0.6, 1.2) * size;
			s.scale.set(s.startScale, s.startScale);
		}
	}

	public function shock(x:Float, y:Float, color:Int, size:Float = 1, life:Float = 0.4):Void
	{
		var s = get();
		s.loadGraphic(Art.ring());
		s.color = color;
		s.setPosition(x - s.width / 2, y - s.height / 2);
		s.total = s.life = life;
		s.startScale = 0.2 * size;
		s.grow = 6;
		s.scale.set(s.startScale, s.startScale);
	}

	public function glow(x:Float, y:Float, color:Int, size:Float = 3, life:Float = 0.3):Void
	{
		var s = get();
		s.loadGraphic(Art.dot());
		s.color = color;
		s.setPosition(x - s.width / 2, y - s.height / 2);
		s.total = s.life = life;
		s.startScale = size;
		s.grow = 0.5;
		s.scale.set(size, size);
	}

	/** A short-lived trail puff, used behind engines. */
	public function puff(x:Float, y:Float, color:Int, vx:Float, vy:Float, size:Float = 0.5, life:Float = 0.35):Void
	{
		var s = get();
		s.loadGraphic(Art.dot());
		s.color = color;
		s.setPosition(x - s.width / 2, y - s.height / 2);
		s.velocity.set(vx, vy);
		s.total = s.life = life;
		s.startScale = size;
		s.grow = -0.6;
		s.scale.set(size, size);
	}
}
