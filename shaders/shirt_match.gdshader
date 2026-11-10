shader_type canvas_item;

// The repaired jump, dash, and roll frames wear a dark blue undershirt.
// The run rig is the older open coat. Lift only those cool dark pixels
// toward the coat's warm shadow so the costume does not pop on the blend.
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float peak = max(color.r, max(color.g, color.b));
	bool shirt = color.a > 0.5 && color.b > color.r + 0.04 && peak < 0.32 && peak > 0.04;
	if (shirt) {
		color.rgb = mix(color.rgb, vec3(0.36, 0.18, 0.14), 0.62);
	}
	COLOR = color;
}
