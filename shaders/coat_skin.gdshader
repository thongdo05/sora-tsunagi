shader_type canvas_item;

// Coat amount 0 = normal skin. 1 = that same skin crushed to black, with red cracks.
// Shading stays in the pixel so it reads as skin changing color, not a separate plate.
uniform float coat : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 black_skin = vec3(lum * 0.07, lum * 0.045, lum * 0.05);
	float crack = smoothstep(0.72, 0.98, sin(UV.x * 46.0 + UV.y * 8.0) * sin(UV.y * 34.0));
	black_skin = mix(black_skin, vec3(0.62, 0.06, 0.04), crack * 0.9);
	vec3 rgb = mix(tex.rgb, black_skin, clamp(coat, 0.0, 1.0));
	COLOR = vec4(rgb, tex.a);
}
