shader_type sky;
// Procedural space sky: gradient, layered nebula with dust lanes, coloured
// stars of varied size, a faint galaxy band, and up to two suns drawn as
// glowing discs with coronas (sizes are angular radii in radians; 0 = none).
// detail: 0 = simple (phones), 1 = full.
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
uniform float detail = 1.0;
// Aurora curtains near the horizon (strength 0 = none) and shooting stars.
uniform vec3 aurora_color : source_color = vec3(0.3, 1.0, 0.6);
uniform float aurora_strength = 0.0;
uniform float shooting_stars = 1.0;

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
	float corona = exp(-max(ang - size, 0.0) / (size * 5.0 + 0.08)) * 0.25 * detail;
	return col * (disc * 3.0 + halo + corona);
}

vec3 stars(vec3 d, float scale, float amount) {
	vec3 c = d * scale;
	vec3 cell = floor(c);
	float h = hash3(cell);
	float s = step(amount, h);
	float h2 = hash3(cell + 7.1);
	float r = mix(0.12, 0.3, h2 * h2);
	float star = s * (1.0 - smoothstep(r * 0.4, r, length(fract(c) - 0.5)));
	vec3 tint = mix(vec3(0.75, 0.85, 1.0), vec3(1.0, 0.85, 0.65), hash3(cell + 3.3));
	return tint * star * (0.8 + 1.4 * h2);
}

void sky() {
	vec3 d = EYEDIR;
	vec3 col = mix(bottom_color, top_color, clamp(d.y * 0.6 + 0.5, 0.0, 1.0));
	vec3 neb;
	float n;
	if (detail < 0.25) {
		// Low: one octave of nebula (the sky covers most of a phone screen,
		// so every noise call here is paid per pixel).
		n = noise3(d * 2.6);
		neb = mix(nebula_a, nebula_b, n) * smoothstep(0.45, 0.8, n) * nebula_strength;
	} else {
		n = noise3(d * 2.6) * 0.65 + noise3(d * 6.3) * 0.35;
		float m = noise3(d * 1.7 + vec3(3.1, 1.2, 7.7));
		neb = mix(nebula_a, nebula_b, m) * smoothstep(0.42, 0.85, n) * nebula_strength;
	}
	if (detail > 0.5) {
		vec3 w = d * 3.0 + vec3(noise3(d * 4.0), noise3(d * 4.0 + 5.0), noise3(d * 4.0 + 9.0)) * 1.5;
		float fine = noise3(w * 3.0) * 0.6 + noise3(w * 7.0) * 0.4;
		neb *= 0.7 + 0.6 * fine;
		float lanes = smoothstep(0.55, 0.75, noise3(d * 5.0 + 11.0));
		neb *= 1.0 - lanes * 0.6;
		neb += mix(nebula_b, nebula_a, fine) * smoothstep(0.6, 0.95, fine * n) * nebula_strength * 0.5;
		// Galaxy band along a tilted great circle.
		vec3 gn = normalize(vec3(0.3, 0.85, 0.42));
		float gx = dot(d, gn) / 0.16;
		float band = exp(-gx * gx);
		col += mix(vec3(0.45, 0.4, 0.55), nebula_a, 0.3) * band * (0.12 + 0.18 * noise3(d * 9.0)) * (1.0 - nebula_strength * 0.3);
		col += stars(d, 260.0, 0.992) * (0.5 + band);
	}
	col += neb;
	col += stars(d, 140.0, star_amount) * 1.2;
	if (aurora_strength > 0.0 && detail > 0.25) {
		// Slow curtains that ripple along the horizon and fade upward.
		float h = d.y;
		float band = smoothstep(0.0, 0.16, h) * (1.0 - smoothstep(0.26, 0.6, h));
		float ang = atan(d.x, d.z);
		float cur = noise3(vec3(ang * 2.6, h * 5.0 - TIME * 0.04, TIME * 0.025));
		float fine = noise3(vec3(ang * 9.0 + 7.0, h * 16.0, TIME * 0.06));
		float a = band * smoothstep(0.42, 0.78, cur) * (0.55 + 0.45 * fine) * aurora_strength;
		vec3 ac = mix(aurora_color, aurora_color.gbr * 0.7 + vec3(0.1, 0.0, 0.2), fine * 0.6);
		col += ac * a * 1.6;
	}
	if (shooting_stars > 0.5 && detail > 0.5) {
		// One streak every few seconds at a new spot, moving along the sky.
		float slot = floor(TIME / 4.5);
		float ph = fract(TIME / 4.5);
		vec3 sd = normalize(vec3(hash3(vec3(slot, 1.0, 2.0)) * 2.0 - 1.0, 0.15 + hash3(vec3(slot, 3.0, 4.0)) * 0.7, hash3(vec3(slot, 5.0, 6.0)) * 2.0 - 1.0));
		vec3 sv = normalize(cross(sd, vec3(0.0, 1.0, 0.0)));
		vec3 head = normalize(sd + sv * (ph * 0.9 - 0.15));
		float along = dot(d - head, sv);
		vec3 closest = normalize(head + sv * clamp(along, -0.1, 0.0));
		float dist = acos(clamp(dot(d, closest), -1.0, 1.0));
		float tail = clamp(1.0 + along / 0.1, 0.0, 1.0);
		float streak = exp(-dist * 700.0) * tail * step(0.02, ph) * (1.0 - smoothstep(0.22, 0.3, ph));
		col += vec3(1.0, 0.96, 0.85) * streak * 2.5;
	}
	col += sun(d, sun1_dir, sun1_color, sun1_size);
	col += sun(d, sun2_dir, sun2_color, sun2_size);
	COLOR = col;
}
