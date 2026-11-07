shader_type spatial;
// Flowing lava for biome rivers (UV.x = metres downstream, UV.y = 0..1
// across) and pools/craters (radial = 1: UV centred on 0.5). Dark crust
// plates drift over glowing molten rock; the crust thickens at the banks.
render_mode cull_disabled;
uniform vec3 lava : source_color = vec3(1.0, 0.35, 0.08);
uniform vec3 lava_hot : source_color = vec3(1.0, 0.81, 0.35);
uniform vec3 crust_color : source_color = vec3(0.06, 0.03, 0.02);
uniform float glow = 3.0;
uniform float crust = 0.6;
uniform float speed = 0.05;
uniform float radial = 0.0;

float hash2(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}
float noise2(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float across = abs(UV.y - 0.5) * 2.0;
	vec2 q = vec2(UV.x * 0.05 - TIME * speed, UV.y * 1.4);
	if (radial > 0.5) {
		vec2 c = UV - 0.5;
		across = clamp(length(c) * 2.0, 0.0, 1.0);
		q = c * 4.0 + vec2(TIME * speed * 0.5, 0.0);
	}
	float n = noise2(q * 3.0) * 0.6 + noise2(q * 7.0 + 3.0) * 0.4;
	float plates = smoothstep(crust - 0.08, crust + 0.08, n + across * 0.4);
	vec3 hot = mix(lava, lava_hot, smoothstep(0.5, 0.0, across) * (1.0 - n));
	ALBEDO = mix(lava * 0.2, crust_color, plates);
	EMISSION = hot * glow * (1.0 - plates) * (0.85 + 0.15 * sin(TIME * 2.0 + UV.x * 0.1));
	ROUGHNESS = mix(0.4, 0.95, plates);
}
