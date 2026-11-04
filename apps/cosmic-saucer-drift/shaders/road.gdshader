shader_type spatial;
// Track surface. Vertex COLOR.rgb = surface tint, COLOR.a * 8 = surface id
// (0 metal, 1 dust, 2 ice, 3 magnetic rail, 4 moss, 5 lava rock).
// UV.x = across the road (0..1), UV.y = metres along / 8.
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec3 neon : source_color = vec3(0.3, 0.9, 1.0);
uniform float glow = 1.6;
uniform float quality = 1.0;

varying float sid;
varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	sid = COLOR.a * 8.0;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = COLOR.rgb;
	float u = UV.x;
	float v = UV.y;
	int s = int(sid + 0.5);
	float edge = 1.0 - smoothstep(0.0, 0.022, min(u, 1.0 - u));
	float dl = min(abs(u - 0.3333), abs(u - 0.6667));
	float dash = (1.0 - smoothstep(0.003, 0.008, dl)) * step(0.5, fract(v * 0.5));
	vec2 g = abs(fract(vec2(u * 6.0, v * 0.5)) - 0.5);
	float panel = smoothstep(0.46, 0.5, max(g.x, g.y));
	vec3 col = base;
	vec3 em = neon * (edge * 1.2 + dash * 0.5) * glow;
	float rough = 0.5;
	float metal = 0.5;
	if (s == 0) {
		col = base * (0.85 - 0.25 * panel);
		rough = 0.45; metal = 0.6;
	} else if (s == 1) {
		float n = vnoise(wpos.xz * 0.35) * 0.6 + vnoise(wpos.xz * 2.1) * 0.4;
		col = base * (0.7 + 0.45 * n);
		rough = 0.95; metal = 0.0;
		em *= 0.5;
	} else if (s == 2) {
		float streak = vnoise(vec2(u * 18.0, v * 0.6));
		col = mix(base, vec3(0.95, 0.98, 1.0), streak * 0.35);
		rough = 0.06; metal = 0.15;
		em += vec3(0.05, 0.12, 0.2) * streak;
	} else if (s == 3) {
		float chev = step(0.55, fract(v * 0.9 - abs(u - 0.5) * 1.6 - TIME * 1.8));
		float rails = 1.0 - smoothstep(0.004, 0.012, min(min(abs(u - 0.1667), abs(u - 0.5)), abs(u - 0.8333)));
		col = base;
		em = neon * (edge * 1.4 + rails * 1.6 + chev * 0.35) * glow;
		rough = 0.3; metal = 0.8;
	} else if (s == 4) {
		float spot = smoothstep(0.72, 0.8, vnoise(wpos.xz * 0.9));
		col = base * (0.75 + 0.4 * vnoise(wpos.xz * 3.0));
		em += vec3(0.2, 1.0, 0.7) * spot * 0.7;
		rough = 0.9; metal = 0.0;
	} else {
		float n = vnoise(wpos.xz * 0.5);
		float crack = 1.0 - smoothstep(0.0, 0.05, abs(n - 0.5));
		col = base * (0.8 + 0.3 * vnoise(wpos.xz * 2.5));
		em += vec3(1.0, 0.35, 0.05) * crack * (0.9 + 0.3 * sin(TIME * 2.0 + wpos.x * 0.1)) * 1.4;
		rough = 0.85; metal = 0.1;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = metal;
	EMISSION = em;
}
