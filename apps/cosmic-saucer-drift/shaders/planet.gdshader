shader_type spatial;
// Distant planet: latitude bands + noise, lit from a fixed sun direction.
render_mode unshaded, cull_back, fog_disabled;
uniform vec3 color_a : source_color = vec3(0.9, 0.7, 0.45);
uniform vec3 color_b : source_color = vec3(0.6, 0.4, 0.3);
uniform vec3 rim_color : source_color = vec3(0.6, 0.8, 1.0);
uniform float bands = 9.0;
uniform vec3 sun_dir = vec3(0.5, 0.3, 0.8);
varying vec3 onorm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() { onorm = NORMAL; }
void fragment() {
	float lat = onorm.y;
	float b = sin(lat * bands + vnoise(vec2(UV.x * 12.0, lat * 6.0)) * 2.5) * 0.5 + 0.5;
	vec3 col = mix(color_a, color_b, b);
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float lit = clamp(dot(wn, normalize(sun_dir)) * 0.8 + 0.35, 0.08, 1.1);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = col * lit + rim_color * rim * 0.6;
}
