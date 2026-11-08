shader_type canvas_item;

// The sheet's core is white. Painted with mix blending, this stays bright honey
// and the channels cannot all clip to white.
uniform vec3 honey : source_color = vec3(1.0, 0.58, 0.12);
uniform float ceiling : hint_range(0.5, 0.95) = 0.86;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = max(tex.r, max(tex.g, tex.b));
	vec3 tinted = mix(tex.rgb * vec3(1.0, 0.72, 0.28), honey * lum, smoothstep(0.28, 0.75, lum));
	float peak = max(tinted.r, max(tinted.g, tinted.b));
	if (peak > ceiling) {
		tinted *= ceiling / peak;
	}
	COLOR = vec4(tinted, tex.a);
}
