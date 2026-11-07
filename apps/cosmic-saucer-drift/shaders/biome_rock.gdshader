shader_type spatial;
// Volcanic biome rock (content/biomes.json palettes): basalt strata, ash on
// upward faces, molten lava veins glowing deep in the cracks (more glow low
// down), and iridescent crystalline faces for the Divine biome. Noise is
// 3D value noise on world position with a sine-free hash (stable on mobile
// GPUs at large coordinates). detail: 0 = Low tier (fewest lookups).
render_mode cull_back;
uniform vec3 rock : source_color = vec3(0.09, 0.07, 0.06);
uniform vec3 rock_hi : source_color = vec3(0.23, 0.19, 0.17);
uniform vec3 ash : source_color = vec3(0.49, 0.46, 0.44);
uniform vec3 lava : source_color = vec3(1.0, 0.35, 0.08);
uniform vec3 lava_hot : source_color = vec3(1.0, 0.81, 0.35);
uniform float crack_width = 0.06;
uniform float crack_glow = 3.0;
uniform float ash_amount = 0.5;
uniform float iridescence = 0.0;
uniform float gloss = 0.3;
uniform float scale = 0.03;
uniform int detail = 2;
varying vec3 wpos;
varying float hgt;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	hgt = clamp(VERTEX.y, 0.0, 1.0);
}

void fragment() {
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 p = wpos * scale;
	float n = noise3(p);
	float strata = 0.5;
	if (detail > 0) {
		n = n * 0.6 + noise3(p * 2.7 + 5.0) * 0.4;
		strata = noise3(vec3(p.x * 0.15, wpos.y * scale * 4.0, p.z * 0.15));
	}
	vec3 col = mix(rock, rock_hi, smoothstep(0.3, 0.95, n * 0.7 + strata * 0.3));
	// Ash settles on upward-facing slopes.
	float up = smoothstep(0.35, 0.85, wn.y + (n - 0.5) * 0.5);
	col = mix(col, ash, up * ash_amount);
	// Crystalline faces: hue shifts with the view angle (Divine).
	float facet = 0.0;
	if (iridescence > 0.0) {
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
		facet = smoothstep(0.5, 0.75, noise3(p * 0.6 + 7.0)) * (1.0 - up);
		vec3 rainbow = 0.5 + 0.5 * cos(6.2831 * (fres * 1.5 + n + vec3(0.0, 0.33, 0.67)));
		col = mix(col, rainbow * (0.4 + rock_hi), iridescence * facet * (0.35 + 0.65 * fres));
	}
	// Lava veins: thin ridged-noise lines, brightest low down and on steep faces.
	// Only in some regions ("vein fields"), mostly near the foot of the rock,
	// never on ash-covered tops: the glow sits deep in the cracks.
	float field = smoothstep(0.45, 0.72, noise3(p * 0.33 + 11.0));
	float r = abs(noise3(p * 0.9 + 3.1) - 0.5);
	if (detail > 1) {
		r = min(r, abs(noise3(p * 2.3 + 1.7) - 0.5) * 1.6);
	}
	float crack = 1.0 - smoothstep(0.0, crack_width, r);
	float low = 1.0 - hgt;
	crack *= field * (low * low * 0.85 + 0.15) * (1.0 - up);
	float pulse = 0.85 + 0.15 * sin(TIME * 1.3 + n * 6.0);
	ALBEDO = mix(col, lava * 0.25, crack);
	EMISSION = mix(lava, lava_hot, crack * crack) * crack * crack_glow * pulse;
	ROUGHNESS = mix(0.92, 0.3, gloss * (1.0 - up));
	METALLIC = iridescence * facet * 0.35;
	SPECULAR = 0.3 + gloss * 0.4;
}
