package fx;

import flixel.system.FlxAssets.FlxShader;

class LightShader extends FlxShader
{
	@:glFragmentSource("
		#pragma header

		void main(void)
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 color = flixel_texture2D(bitmap, uv);
			float a = color.a;
			if (a < 0.02)
			{
				gl_FragColor = vec4(0.0);
				return;
			}

			vec3 rgb = color.rgb / max(a, 0.0001);
			float top = 1.0 - uv.y;
			float shade = mix(0.9, 1.04, smoothstep(0.0, 1.0, top));
			float spec = smoothstep(0.14, 0.0, uv.y);

			vec3 lit = rgb * shade;
			lit += vec3(0.9, 0.95, 1.0) * spec * 0.08;

			gl_FragColor = vec4(clamp(lit, 0.0, 1.0) * a, a);
		}
	")
	public function new()
	{
		super();
	}
}
