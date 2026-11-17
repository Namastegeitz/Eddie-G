shader_type spatial;
// Ion Shield bubble: hex cells, bright fresnel edge, pulse ripples.
render_mode blend_add, unshaded, cull_back, depth_draw_never, shadows_disabled;
uniform vec3 color : source_color = vec3(0.35, 0.8, 1.0);
uniform float power = 1.0;
float hexd(vec2 p) {
	p = abs(p);
	return max(dot(p, normalize(vec2(1.0, 1.732))), p.x);
}
void fragment() {
	vec2 uv = UV * vec2(18.0, 9.0);
	vec2 r = vec2(1.0, 1.732);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	float edge_hex = smoothstep(0.42, 0.5, hexd(g));
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float wave = 0.5 + 0.5 * sin(UV.y * 30.0 - TIME * 6.0);
	ALBEDO = color * power * (f * 1.3 + edge_hex * (0.25 + 0.35 * wave) + 0.04);
}
