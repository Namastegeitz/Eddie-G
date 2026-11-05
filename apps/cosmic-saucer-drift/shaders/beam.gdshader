shader_type spatial;
// Energy beam (laser, tractor): additive, soft at the edges, with energy
// bands streaming along it. UV.y runs along the beam (cylinder height).
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 color : source_color = vec3(0.3, 1.0, 0.95);
uniform float power = 1.0;
uniform float flow = 6.0;       // band speed (negative pulls toward the start)
uniform float bands = 14.0;
uniform float core = 0.0;       // 1 = white-hot core
void fragment() {
	// Brightest through the middle, but never fading out completely, so a
	// beam pointing straight away from the camera still reads.
	float edge = mix(0.5, 1.0, pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.4));
	float b = 0.55 + 0.45 * sin((UV.y * bands - TIME * flow) * 6.2831);
	vec3 c = mix(color, vec3(1.0), core * 0.8);
	ALBEDO = c * edge * power * (0.6 + 0.6 * b);
}
