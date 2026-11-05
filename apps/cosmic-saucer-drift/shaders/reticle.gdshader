shader_type spatial;
// Lock-on / impact target marker on a flat quad: spinning dashed ring with
// corner ticks, pulsing. Drawn on top so it reads through the scenery.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;
uniform vec3 color : source_color = vec3(1.0, 0.25, 0.15);
uniform float power = 1.0;
uniform float spin = 2.0;
uniform bool billboard = false;
void vertex() {
	if (billboard) {
		float s = length(MODEL_MATRIX[0].xyz);
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	}
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x) + TIME * spin;
	float ring = smoothstep(0.08, 0.0, abs(r - 0.78)) * step(0.35, fract(a / 6.2831 * 8.0));
	float inner = smoothstep(0.05, 0.0, abs(r - 0.42));
	float cross = (smoothstep(0.04, 0.0, abs(p.x)) + smoothstep(0.04, 0.0, abs(p.y))) * step(0.5, r) * step(r, 0.95);
	float pulse = 0.65 + 0.35 * sin(TIME * 10.0);
	ALBEDO = color * power * pulse * (ring + inner * 0.8 + cross * 0.7) * 1.6;
}
