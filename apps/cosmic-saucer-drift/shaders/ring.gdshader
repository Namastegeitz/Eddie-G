shader_type spatial;
// Planetary ring on a flat quad: bands by radius, transparent gaps.
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, fog_disabled;
uniform vec3 color_a : source_color = vec3(0.95, 0.85, 0.65);
uniform vec3 color_b : source_color = vec3(0.7, 0.55, 0.45);
uniform float inner = 0.55;
float hash(float p) { return fract(sin(p * 127.1) * 43758.5453); }
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float band = hash(floor(r * 60.0)) * 0.6 + 0.4;
	float a = smoothstep(inner, inner + 0.02, r) * (1.0 - smoothstep(0.97, 1.0, r)) * band;
	ALBEDO = mix(color_b, color_a, band);
	ALPHA = a * 0.85;
}
