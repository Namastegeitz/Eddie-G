shader_type spatial;
// Animated chevrons on a boost pad (UV.y runs along the road, 1 = ahead).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec3 color : source_color = vec3(1.0, 0.3, 0.85);
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float c = fract(UV.y * 3.0 - x * 0.6 - TIME * 2.5);
	float chev = smoothstep(0.0, 0.08, c) * (1.0 - smoothstep(0.38, 0.46, c));
	float edge = 1.0 - smoothstep(0.0, 0.06, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	ALBEDO = color * (chev * 2.2 + edge * 1.5 + 0.12);
}
