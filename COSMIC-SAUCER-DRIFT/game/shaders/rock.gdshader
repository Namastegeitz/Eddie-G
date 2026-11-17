shader_type spatial;
// Scenery rock (spires, boulders, asteroids): layered strata by height,
// noise breakup, and dust/frost settling on upward faces. Works on MultiMesh
// instances (MODEL_MATRIX is per instance).
render_mode blend_mix, cull_back;
uniform vec3 color : source_color = vec3(0.5, 0.25, 0.15);
uniform vec3 top : source_color = vec3(0.8, 0.55, 0.4);
uniform float strata = 1.0;
uniform float detail = 1.0;
uniform float rough_v = 0.92;
varying vec3 wpos;
varying vec3 wn;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Inverse-transpose: spires are scaled about (10, 100, 10), and the plain
	// model matrix tipped their side normals up so 75% of them got "top dust".
	wn = normalize(transpose(inverse(mat3(MODEL_MATRIX))) * NORMAL);
}
void fragment() {
	vec3 col = color;
	if (detail > 0.25) {
		float warp = vnoise(wpos.xz * 0.04) * 8.0;
		float band = sin(wpos.y * 0.55 + warp) * 0.5 + 0.5;
		float band2 = sin(wpos.y * 2.3 + warp * 2.0) * 0.5 + 0.5;
		float n = vnoise(vec2(wpos.x + wpos.z, wpos.y) * 0.35) * 0.6 + vnoise(vec2(wpos.x - wpos.z, wpos.y) * 1.7) * 0.4;
		col *= mix(1.0, 0.72 + 0.4 * band + 0.12 * band2, strata);
		col *= 0.8 + 0.4 * n;
		float up = smoothstep(0.5, 0.85, normalize(wn).y);
		col = mix(col, top, up * 0.75);
	}
	ALBEDO = col;
	ROUGHNESS = rough_v;
	METALLIC = 0.0;
	SPECULAR = 0.3;
}
