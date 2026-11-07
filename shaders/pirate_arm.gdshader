shader_type canvas_item;

uniform sampler2D arm_mask : filter_linear, repeat_disable;
uniform float attack : hint_range(0.0, 1.0) = 0.0;
uniform vec3 skin_light : source_color = vec3(0.871, 0.620, 0.478);
uniform vec3 skin_shadow : source_color = vec3(0.573, 0.329, 0.235);

// arm_mask.r = coated arm surface (drawn as skin at rest)
// arm_mask.g = lightning and aura (hidden at rest)
// arm_mask.b = top-to-bottom shade for the skin

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 m = texture(arm_mask, UV);
	float rest = 1.0 - clamp(attack, 0.0, 1.0);
	float shade = clamp(m.b, 0.0, 1.0);
	vec3 skin = mix(skin_light, skin_shadow, shade);
	float grain = fract(sin(dot(UV, vec2(48.7, 91.3))) * 43758.5453);
	skin *= mix(0.94, 1.05, grain);

	vec3 rgb = mix(tex.rgb, skin, m.r * rest);
	float alpha = tex.a;
	if (m.r > 0.5) {
		alpha = mix(tex.a, 1.0, rest);
	}
	if (m.g > 0.5) {
		alpha = mix(alpha, 0.0, rest);
	}

	// Hide only unclaimed lightning. Surface pixels stay, so the forearm is not punched out.
	float spark = 0.0;
	if (m.r < 0.5 && m.g < 0.5 && UV.x > 0.70 && UV.y > 0.04 && UV.y < 0.50) {
		bool red = tex.r > tex.g + 0.16 && tex.g < 0.50 && tex.r > 0.28;
		bool purple = tex.b > 0.22 && tex.r > 0.15 && tex.g + 0.06 < max(tex.r, tex.b) && tex.a > 0.15;
		bool coat = UV.x < 0.74 && tex.g > 0.25 && tex.a > 0.85 && tex.r > tex.b;
		if ((red || purple) && !coat) {
			spark = 1.0;
		}
	}
	alpha *= mix(1.0, 1.0 - spark, rest);

	COLOR = vec4(rgb, alpha);
}
