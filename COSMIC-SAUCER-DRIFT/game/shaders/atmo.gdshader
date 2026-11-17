shader_type spatial;
// Atmosphere halo: a slightly larger shell drawn from the inside (back
// faces), brightest at the planet's edge and on its sunlit side.
render_mode unshaded, blend_add, cull_front, depth_draw_never, fog_disabled, shadows_disabled;
uniform vec3 color : source_color = vec3(0.5, 0.75, 1.0);
uniform vec3 sun_dir = vec3(0.5, 0.3, 0.8);
uniform float inner = 0.94;   // planet radius / shell radius
varying vec3 opos;
void vertex() { opos = VERTEX; }
void fragment() {
	float f = abs(dot(NORMAL, VIEW));
	float edge = sqrt(max(1.0 - inner * inner, 0.0001));
	float k = smoothstep(0.0, edge, f);
	vec3 wn = normalize((MODEL_MATRIX * vec4(opos, 0.0)).xyz);
	float day = smoothstep(-0.4, 0.5, dot(wn, normalize(sun_dir)));
	ALBEDO = color * k * k * (0.2 + 0.9 * day);
}
