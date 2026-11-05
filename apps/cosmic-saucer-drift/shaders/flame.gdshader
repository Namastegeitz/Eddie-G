shader_type spatial;
// Engine flame: additive, flickering, hot white core fading to the trail
// colour. UV.y runs from the nozzle (0) to the tip (1) on a cone.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 color : source_color = vec3(0.3, 0.8, 1.0);
uniform float power = 1.0;
uniform float core = 0.0;     // 1 = white-hot inner flame
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	float along = UV.y;
	float n = vnoise(vec2(UV.x * 8.0, along * 5.0 - TIME * 14.0));
	float fade = pow(1.0 - along, 1.6) * (0.65 + 0.5 * n);
	float side = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), 0.8);
	vec3 c = mix(color, vec3(1.0, 0.97, 0.9), core * 0.85 + (1.0 - along) * 0.25);
	ALBEDO = c * fade * side * power * 1.8;
}
