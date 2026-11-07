package fx;

import flixel.system.FlxAssets.FlxShader;

class PlasmaShader extends FlxShader
{
	@:glFragmentSource("
		#pragma header

		uniform float uTime;
		uniform float uStyle;

		void main(void)
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 texel = texture2D(bitmap, uv);
			float t = uTime;
			float play = step(0.5, uStyle) * (1.0 - step(1.5, uStyle));
			float over = step(1.5, uStyle);
			float menu = 1.0 - max(play, over);

			vec2 drift = vec2(0.0, -t * 0.045) * menu + vec2(t * 0.05, -t * 0.032) * play + vec2(t * 0.012, -t * 0.018) * over;
			vec2 p = (uv - 0.5) * vec2(1.0, 1.7777778) + drift;
			float r = length(p);
			float ang = atan(p.y, p.x);
			float spin = 0.04 * menu + 0.08 * play + 0.025 * over;
			float twist = 0.5 * menu + 0.95 * play + 0.32 * over;
			ang += t * spin + r * twist;
			ang += sin(r * 1.5 - t * 0.14) * (0.1 * menu + 0.16 * play + 0.07 * over);
			p = vec2(cos(ang), sin(ang)) * r;
			p.x += sin(p.y * 1.15 + t * 0.16) * 0.07;
			p.y += cos(p.x * 1.0 - t * 0.12) * 0.07;

			float freq = 1.15 * menu + 2.15 * play + 1.25 * over;
			float n = 0.0;
			n += sin(p.x * freq + t * 0.24);
			n += sin(p.y * freq * 0.9 - t * 0.19);
			n += sin((p.x + p.y) * freq * 0.7 + t * 0.11);
			n += sin(length(p) * freq * 1.25 - t * 0.2);
			n *= 0.25;
			float v = n * 0.5 + 0.5;

			float sharp = 3.2 * menu + 9.0 * play + 5.0 * over;
			float thread = pow(clamp(0.5 + 0.5 * sin(n * (2.6 + 2.2 * play) - t * 0.32), 0.0, 1.0), sharp);

			vec3 deep = vec3(0.02, 0.035, 0.08) * menu + vec3(0.012, 0.04, 0.07) * play + vec3(0.04, 0.012, 0.055) * over;
			vec3 body = vec3(0.045, 0.11, 0.26) * menu + vec3(0.03, 0.16, 0.3) * play + vec3(0.1, 0.035, 0.15) * over;
			vec3 energy = vec3(0.15, 0.38, 0.72) * menu + vec3(0.12, 0.58, 0.74) * play + vec3(0.4, 0.12, 0.26) * over;
			vec3 core = vec3(0.8, 0.9, 1.0) * menu + vec3(0.68, 0.94, 1.0) * play + vec3(0.95, 0.7, 0.76) * over;

			vec3 col = mix(deep, body, smoothstep(0.06, 0.68, v));
			col = mix(col, energy, smoothstep(0.46, 0.9, v) * (0.52 + 0.22 * play));
			col += core * thread * (0.32 + 0.16 * play);

			float vig = smoothstep(1.15, 0.28, length((uv - 0.5) * vec2(1.02, 1.18)));
			col *= mix(0.55, 1.0, vig);

			vec2 pix = uv * max(openfl_TextureSize, vec2(1.0));
			float cell = 28.0;
			vec2 id = floor(pix / cell);
			vec2 local = mod(pix, cell) - vec2(cell * 0.5);
			float point = smoothstep(1.75, 0.55, length(local));
			float major = max(step(mod(id.x, 4.0), 0.001), step(mod(id.y, 4.0), 0.001));
			col += vec3(0.62, 0.78, 0.92) * point * (0.16 + 0.14 * major);

			gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0) * texel.a;
		}
	")
	public function new()
	{
		super();
		uTime.value = [0.0];
		uStyle.value = [0.0];
	}
}
