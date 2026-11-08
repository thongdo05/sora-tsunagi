shader_type canvas_item;

uniform float fade_x: hint_range(0.0, 0.45) = 0.1;
uniform float fade_top: hint_range(0.0, 0.8) = 0.0;
uniform float fade_bottom: hint_range(0.0, 0.8) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
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
