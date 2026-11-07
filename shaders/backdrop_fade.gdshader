shader_type canvas_item;

uniform float fade: hint_range(0.01, 0.4) = 0.14;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float edge = min(UV.x / fade, (1.0 - UV.x) / fade);
	color.a *= clamp(edge, 0.0, 1.0);
	COLOR = color;
}
