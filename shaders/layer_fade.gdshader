shader_type canvas_item;

uniform float fade_x: hint_range(0.0, 0.45) = 0.1;
uniform float fade_top: hint_range(0.0, 0.8) = 0.0;
uniform float fade_bottom: hint_range(0.0, 0.8) = 0.0;
uniform float shimmer: hint_range(0.0, 1.5) = 0.0;

void fragment() {
	vec2 uv = UV;
	if (shimmer > 0.001) {
		uv.x += sin(UV.y * 18.0 + TIME * 0.45) * 0.0016 * shimmer;
		uv.y += sin(UV.x * 26.0 + TIME * 0.7) * 0.0024 * shimmer;
	}
	vec4 color = texture(TEXTURE, uv);
	if (shimmer > 0.001) {
		float glint = sin(UV.x * 40.0 + TIME * 0.9) * sin(UV.y * 8.0 - TIME * 0.5);
		color.rgb += vec3(0.45, 0.62, 0.8) * max(glint, 0.0) * 0.045 * shimmer;
	}
	float edge = 1.0;
	if (fade_x > 0.001) {
		edge = min(edge, clamp(min(UV.x / fade_x, (1.0 - UV.x) / fade_x), 0.0, 1.0));
	}
	if (fade_top > 0.001) {
		edge = min(edge, clamp(UV.y / fade_top, 0.0, 1.0));
	}
	if (fade_bottom > 0.001) {
		edge = min(edge, clamp((1.0 - UV.y) / fade_bottom, 0.0, 1.0));
	}
	color.a *= edge;
	COLOR = color;
}
