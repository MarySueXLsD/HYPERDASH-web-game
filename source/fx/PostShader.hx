package fx;

import flixel.system.FlxAssets.FlxShader;

/** Camera post-process: a dithered vignette and a dithered red hit-flash. No filtering of the art itself. */
class PostShader extends FlxShader
{
	@:glFragmentSource("
		#pragma header

		uniform float uTime;
		uniform float uAberr;
		uniform float uScan;
		uniform float uTintR;
		uniform float uPixel;

		float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

		float bayer2(vec2 a) { a = floor(a); return fract(dot(a, vec2(0.5, a.y * 0.75))); }
		float bayer4(vec2 a) { return (bayer2(0.5 * a) * 0.25 + bayer2(a)) / 1.25; }

		void main(void)
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 base = flixel_texture2D(bitmap, uv);
			vec3 col = base.rgb;
			// Red hit-flash only. No vignette, grain or dither over the art.
			col = mix(col, col * vec3(1.4, 0.5, 0.55), step(0.25, uTintR));
			gl_FragColor = vec4(col, base.a);
		}
	")
	public function new()
	{
		super();
		uTime.value = [0.0];
		uAberr.value = [0.0];
		uScan.value = [0.0];
		uPixel.value = [2.0];
		uTintR.value = [0.0];
	}
}
