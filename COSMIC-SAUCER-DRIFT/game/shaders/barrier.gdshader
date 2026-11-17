shader_type spatial;
// Track barriers: metal panels every 2 m with seams, grime, and a row of
// running lights along the inner faces in the world's neon colour.
// UV.x runs around the barrier profile (inner faces: < 0.3 right, > 0.7 left),
// UV.y = metres along / 4.
render_mode blend_mix, cull_back;
uniform vec3 color : source_color = vec3(0.2, 0.2, 0.3);
uniform vec3 neon : source_color = vec3(0.3, 0.9, 1.0);
uniform float detail = 1.0;
uniform float metal_k = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	float seg = UV.y * 2.0;
	vec3 col = color;
	vec3 em = vec3(0.0);
	if (detail > 0.25) {
		float w = fwidth(seg) * 1.5 + 0.0001;
		float seam = 1.0 - smoothstep(0.0, w, abs(fract(seg + 0.5) - 0.5));
		col *= (0.88 + 0.16 * hash(vec2(floor(seg), 3.0))) * (1.0 - 0.45 * seam);
		col *= 0.9 + 0.1 * vnoise(vec2(UV.x * 40.0, UV.y * 30.0));
		float inner_mid = min(abs(UV.x - 0.15), abs(UV.x - 0.85));
		float strip = 1.0 - smoothstep(0.012, 0.03, inner_mid);
		float dash = step(0.35, fract(seg * 2.0));
		em += neon * strip * dash * 1.4;
		col = mix(col, neon * 0.3, strip * dash);
	}
	ALBEDO = col;
	METALLIC = 0.7 * metal_k;
	ROUGHNESS = 0.35;
	EMISSION = em;
}
