shader_type sky;
// Cheap procedural space sky: gradient + two nebula colours + star field.
uniform vec3 top_color : source_color = vec3(0.04, 0.02, 0.1);
uniform vec3 bottom_color : source_color = vec3(0.1, 0.04, 0.16);
uniform vec3 nebula_a : source_color = vec3(0.6, 0.2, 0.8);
uniform vec3 nebula_b : source_color = vec3(0.2, 0.4, 0.95);
uniform float nebula_strength = 0.75;
uniform float star_amount = 0.985;

float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
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
	float tw = 0.7 + 0.3 * sin(TIME * 2.0 + h * 50.0);
	col += vec3(star * tw * 1.6);
	COLOR = col;
}
