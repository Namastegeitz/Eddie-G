shader_type spatial;
// Cockpit glass: nearly clear in the middle, bright at the edges (fresnel),
// with a soft sky-tinted sheen. Drawn after the pilot inside it.
render_mode blend_mix, cull_back, depth_draw_never, specular_schlick_ggx;
uniform vec3 tint : source_color = vec3(0.7, 0.9, 1.0);
uniform float edge = 0.75;
uniform float base_alpha = 0.06;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
	ALBEDO = tint;
	ALPHA = clamp(base_alpha + f * edge, 0.0, 0.92);
	METALLIC = 0.0;
	ROUGHNESS = 0.03;
	SPECULAR = 1.0;
	EMISSION = tint * f * 0.35;
}
