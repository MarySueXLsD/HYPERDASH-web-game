package fx;

import flixel.system.FlxAssets.FlxShader;

/** Hyperspace backdrop: drifting nebula plus radial star streaks that stretch with speed. */
class StarShader extends FlxShader
{
	@:glFragmentSource("
		#pragma header

		#ifdef GL_FRAGMENT_PRECISION_HIGH
		precision highp float;
		#endif

		uniform float uTime;
		uniform float uTravel;
		uniform float uStretch;
		uniform vec3 uTintA;
		uniform vec3 uTintB;
		uniform vec2 uCenter;
		uniform float uFlash;

		float hash(float n) { return fract(sin(n) * 43758.5453123); }

		float noise(vec2 p)
		{
			vec2 i = floor(p);
			vec2 f = fract(p);
			f = f * f * (3.0 - 2.0 * f);
			float n = i.x + i.y * 57.0;
			return mix(mix(hash(n), hash(n + 1.0), f.x), mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
		}

		float fbm(vec2 p)
		{
			float v = 0.0;
			float a = 0.5;
			for (int i = 0; i < 4; i++)
			{
				v += noise(p) * a;
				p = p * 2.03 + vec2(1.7, 9.2);
				a *= 0.5;
			}
			return v;
		}

		float streaks(vec2 d, float bins, float seed, float travel)
		{
			float r = length(d);
			float a = atan(d.y, d.x);
			float fb = (a / 6.2831853 + 0.5) * bins;
			float id = floor(fb);
			float fa = fract(fb) - 0.5;
			float h1 = hash(id * 1.31 + seed);
			float h2 = hash(id * 7.77 + seed * 3.1);
			float h3 = hash(id * 3.17 + seed * 5.3);
			float p = fract(h1 + travel * (0.35 + h2 * 0.65));
			float head = p * p * 1.6;
			float len = 0.004 + uStretch * p * p * 0.5;
			float body = smoothstep(head - len, head, r) * (1.0 - smoothstep(head, head + 0.004, r));
			float width = abs(fa) * 6.2831853 / bins * r;
			float thick = 0.0016 + p * 0.0035;
			float m = body * smoothstep(thick, 0.0, width);
			return m * step(0.35, h3) * smoothstep(0.0, 0.25, p) * (0.5 + h2 * 0.8);
		}

		void main(void)
		{
			// Everything is computed per art pixel (2 screen pixels), so edges are crisp.
			vec2 cellPx = floor(openfl_TextureCoordv * vec2(270.0, 480.0));
			vec2 uv = (cellPx + 0.5) / vec2(270.0, 480.0);
			vec2 d = (uv - uCenter) * vec2(0.5625, 1.0);
			float t = uTime;

			// Nebula: two flat layers with hard contours. No dither, no gradients.
			vec2 np = uv * vec2(1.2, 2.0) + vec2(t * 0.006, -uTravel * 0.04);
			float neb = fbm(np);
			float neb2 = fbm(np * 1.6 + vec2(4.0, -uTravel * 0.025));
			vec3 col = vec3(0.071, 0.055, 0.133);
			col = mix(col, mix(col, uTintA, 0.22), step(0.62, neb));
			col = mix(col, mix(col, uTintA, 0.4), step(0.74, neb));
			col = mix(col, mix(col, uTintB, 0.2), step(0.7, neb2) * (1.0 - step(0.74, neb)));

			// Warp streaks, one art pixel wide.
			float s = 0.0;
			s += streaks(d, 160.0, 1.0, uTravel);
			s += streaks(d, 110.0, 7.0, uTravel * 0.8);
			s += streaks(d, 70.0, 13.0, uTravel * 0.6);
			vec3 starCol = mix(vec3(0.95, 0.95, 0.96), uTintB, step(0.5, uStretch) * 0.3);
			col = mix(col, starCol, step(0.32, s));

			// Fixed stars in three sizes: single pixels, a few brighter ones, and rare 4-point sparkles.
			float h = hash(cellPx.x * 13.1 + cellPx.y * 71.7);
			col = mix(col, vec3(0.54, 0.51, 0.65), step(0.994, h));
			col = mix(col, vec3(0.95, 0.95, 0.96), step(0.9985, h));
			vec2 big = floor(cellPx / 3.0);
			float hb = hash(big.x * 31.7 + big.y * 17.3 + 5.0);
			vec2 inCell = cellPx - big * 3.0;
			float cross = step(0.9965, hb) * (step(abs(inCell.x - 1.0), 0.5) + step(abs(inCell.y - 1.0), 0.5));
			float blink = step(0.0, sin(t * 1.7 + hb * 40.0));
			col = mix(col, vec3(0.79, 0.76, 0.87), clamp(cross, 0.0, 1.0) * blink);

			// Flash: hard white, fading out by snapping rather than blending.
			col = mix(col, vec3(0.95, 0.95, 0.96), step(0.5, uFlash));
			gl_FragColor = vec4(col, 1.0);
		}
	")
	public function new()
	{
		super();
		uTime.value = [0.0];
		uTravel.value = [0.0];
		uStretch.value = [0.0];
		uTintA.value = [0.1, 0.24, 1.0];
		uTintB.value = [0.24, 0.94, 1.0];
		uCenter.value = [0.5, 0.45];
		uFlash.value = [0.0];
	}
}
