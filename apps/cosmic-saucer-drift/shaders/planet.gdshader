shader_type spatial;
// Distant planet: latitude bands + noise (gas giants), craters (rocky),
// drifting cloud streaks, a soft day/night terminator and an atmosphere rim,
// lit from a fixed sun direction.
render_mode unshaded, cull_back, fog_disabled;
uniform vec3 color_a : source_color = vec3(0.9, 0.7, 0.45);
uniform vec3 color_b : source_color = vec3(0.6, 0.4, 0.3);
uniform vec3 rim_color : source_color = vec3(0.6, 0.8, 1.0);
uniform float bands = 9.0;
uniform vec3 sun_dir = vec3(0.5, 0.3, 0.8);
uniform float detail = 1.0;
varying vec3 onorm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float crater(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p) - 0.5;
	float r = 0.15 + 0.25 * hash(i + 4.0);
	float d = length(f + (vec2(hash(i), hash(i + 9.0)) - 0.5) * 0.4);
	float on = step(0.55, hash(i + 2.0));
	return on * (smoothstep(r, r * 0.8, d) * 0.5 - smoothstep(r * 1.1, r, d) * smoothstep(r * 0.9, r, d) * 0.6);
}
void vertex() { onorm = NORMAL; }
void fragment() {
	float lat = onorm.y;
	float lon = atan(onorm.z, onorm.x);
	float b = sin(lat * bands + vnoise(vec2(UV.x * 12.0, lat * 6.0)) * 2.5) * 0.5 + 0.5;
	vec3 col = mix(color_a, color_b, b);
	if (detail > 0.5) {
		float giant = smoothstep(10.0, 13.0, bands);
		vec2 sp = vec2(lon * 3.0, lat * 4.0);
		float fine = vnoise(sp * 3.0) * 0.5 + vnoise(sp * 7.0) * 0.3 + vnoise(sp * 15.0) * 0.2;
		col *= 0.85 + 0.3 * fine;
		// Craters on rocky worlds, swirling storms on giants.
		float cr = crater(sp * 2.2) + crater(sp * 5.0) * 0.6;
		col *= 1.0 + cr * (1.0 - giant) * 0.6;
		float swirl = vnoise(vec2(lon * 6.0 + sin(lat * 18.0) * 0.6 + TIME * 0.004, lat * 30.0));
		col = mix(col, mix(color_a, vec3(1.0), 0.4), smoothstep(0.7, 0.9, swirl) * giant * 0.5);
	}
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float ndl = dot(wn, normalize(sun_dir));
	float lit = smoothstep(-0.35, 0.7, ndl) * 0.95 + 0.12;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float day = smoothstep(-0.35, 0.3, ndl);
	ALBEDO = col * lit + rim_color * rim * (0.25 + 0.75 * day) * 0.8;
}
