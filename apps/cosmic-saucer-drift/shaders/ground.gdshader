shader_type spatial;
// Far-below moon surface for jungle / ice / lava themes.
render_mode cull_disabled;
uniform vec3 base : source_color = vec3(0.1, 0.2, 0.12);
uniform vec3 glow_color : source_color = vec3(0.2, 1.0, 0.6);
uniform float glow_amount = 0.6;
uniform float scale = 0.02;
uniform int mode = 0; // 0 spots, 1 cracks (lava), 2 frost, 3 cloud tops
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz * scale;
	float n = vnoise(p) * 0.6 + vnoise(p * 4.0) * 0.4;
	vec3 col = base * (0.6 + 0.6 * n);
	vec3 em = vec3(0.0);
	if (mode == 1) {
		float crack = 1.0 - smoothstep(0.0, 0.035, abs(vnoise(p * 2.0) - 0.5));
		em = glow_color * crack * (0.8 + 0.4 * sin(TIME + p.x * 3.0)) * glow_amount * 2.0;
	} else if (mode == 2) {
		em = glow_color * smoothstep(0.75, 0.9, n) * glow_amount;
	} else if (mode == 3) {
		float band = sin(wpos.z * 0.004 + vnoise(p * 1.5 + vec2(TIME * 0.02, 0.0)) * 3.0) * 0.5 + 0.5;
		col = mix(base, glow_color, band * 0.6) * (0.75 + 0.35 * n);
		em = glow_color * band * 0.15;
	} else {
		em = glow_color * smoothstep(0.78, 0.84, vnoise(p * 6.0)) * glow_amount;
	}
	ALBEDO = col;
	ROUGHNESS = 0.9;
	EMISSION = em;
}
