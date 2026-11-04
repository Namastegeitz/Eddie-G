shader_type sky;
// Procedural space sky: gradient, nebula, stars, and up to two suns drawn as
// glowing discs (sizes are angular radii in radians; 0 = no sun).
uniform vec3 top_color : source_color = vec3(0.04, 0.02, 0.1);
uniform vec3 bottom_color : source_color = vec3(0.1, 0.04, 0.16);
uniform vec3 nebula_a : source_color = vec3(0.6, 0.2, 0.8);
uniform vec3 nebula_b : source_color = vec3(0.2, 0.4, 0.95);
uniform float nebula_strength = 0.75;
uniform float star_amount = 0.985;
uniform vec3 sun1_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 sun1_color : source_color = vec3(0.0);
uniform float sun1_size = 0.0;
uniform vec3 sun2_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 sun2_color : source_color = vec3(0.0);
uniform float sun2_size = 0.0;

float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

vec3 sun(vec3 d, vec3 dir, vec3 col, float size) {
	if (size <= 0.0) return vec3(0.0);
	float c = dot(d, normalize(dir));
	float ang = acos(clamp(c, -1.0, 1.0));
	float disc = 1.0 - smoothstep(size * 0.92, size, ang);
	float halo = exp(-max(ang - size, 0.0) / (size * 1.5 + 0.02)) * 0.6;
	return col * (disc * 3.0 + halo);
}

void sky() {
	vec3 d = EYEDIR;
	vec3 col = mix(bottom_color, top_color, clamp(d.y * 0.6 + 0.5, 0.0, 1.0));
	float n = noise3(d * 2.6) * 0.65 + noise3(d * 6.3) * 0.35;
	float m = noise3(d * 1.7 + vec3(3.1, 1.2, 7.7));
	col += mix(nebula_a, nebula_b, m) * smoothstep(0.42, 0.85, n) * nebula_strength;
	vec3 c = d * 140.0;
	vec3 cell = floor(c);
	float h = hash3(cell);
	float star = step(star_amount, h) * (1.0 - smoothstep(0.08, 0.32, length(fract(c) - 0.5)));
	col += vec3(star * 1.4);
	col += sun(d, sun1_dir, sun1_color, sun1_size);
	col += sun(d, sun2_dir, sun2_color, sun2_size);
	COLOR = col;
}
