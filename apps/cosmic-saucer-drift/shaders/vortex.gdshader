shader_type spatial;
// Gravity Well: spiral arms spinning into a dark centre, on a flat quad.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 color : source_color = vec3(0.55, 0.3, 1.0);
uniform float power = 1.0;
uniform float arms = 3.0;
uniform float spin = 3.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float s = sin(a * arms - r * 10.0 + TIME * spin) * 0.5 + 0.5;
	float arm = smoothstep(0.35, 0.95, s);
	float fade = smoothstep(1.0, 0.5, r) * smoothstep(0.04, 0.28, r);
	float core = smoothstep(0.3, 0.0, r);
	ALBEDO = (color * arm * fade * 1.6 + vec3(0.9, 0.8, 1.0) * core * 0.6) * power;
}
