shader_type spatial;
// Craft paint: glossy toy-like finish with panel seams, rivets, running
// lights, a two-tone underside, organic veins or dragon scales, and a
// white hit flash. UVs come from MeshKit (around / along the shape).
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec3 paint : source_color = vec3(0.8, 0.2, 0.3);
uniform vec3 under : source_color = vec3(0.3, 0.1, 0.12);
uniform vec3 accent : source_color = vec3(0.3, 0.9, 1.0);
uniform float metal = 0.55;
uniform float rough = 0.25;
uniform float coat = 1.0;        // clearcoat (toy shine)
uniform float rim_amt = 0.35;
uniform int pattern = 0;         // 0 panels, 1 veins, 2 scales, 3 plain, 4 sail grid
uniform float panels_u = 12.0;
uniform float panels_v = 3.0;
uniform float under_v = 2.0;     // UV.y beyond which the underside colour starts (>1 = none)
uniform float lights = 0.0;      // running light strength
uniform float light_count = 20.0;
uniform float light_v = 0.5;     // UV.y of the light row
uniform float light_w = 0.04;
uniform float chase = 0.0;       // light chase speed (boost)
uniform float flash = 0.0;       // hit flash 0..1
uniform vec3 flash_color : source_color = vec3(1.0, 0.95, 0.9);
uniform float detail = 1.0;      // 0 on low quality

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float line_aa(float x) {
	float w = fwidth(x) * 1.2 + 0.0001;
	float d = abs(fract(x + 0.5) - 0.5);
	return 1.0 - smoothstep(0.0, w, d);
}

void fragment() {
	vec2 uv = UV;
	vec3 col = paint;
	float r = rough;
	float m = metal;
	vec3 em = vec3(0.0);
	float t = smoothstep(under_v - 0.02, under_v + 0.02, uv.y);
	col = mix(paint, under, t);
	if (detail > 0.5) {
		if (pattern == 0) {
			float seam = max(line_aa(uv.x * panels_u), line_aa(uv.y * panels_v));
			col *= 1.0 - 0.45 * seam;
			r = mix(r, 0.7, seam);
			vec2 cell = vec2(uv.x * panels_u, uv.y * panels_v);
			vec2 f = fract(cell) - 0.5;
			vec2 rv = vec2(f.x * 6.0, (abs(f.y) - 0.38) * 26.0);
			float rivet = (1.0 - smoothstep(0.25, 0.45, length(vec2(fract(rv.x) - 0.5, rv.y)))) * step(abs(f.x), 0.4);
			col = mix(col, col * 1.35 + 0.05, rivet * 0.6);
			col *= 0.94 + 0.06 * vnoise(uv * vec2(80.0, 40.0));
		} else if (pattern == 1) {
			float n = vnoise(uv * vec2(14.0, 9.0)) * 0.65 + vnoise(uv * vec2(33.0, 21.0)) * 0.35;
			float vein = 1.0 - smoothstep(0.0, 0.05, abs(n - 0.5));
			col = mix(col, under, vnoise(uv * 6.0) * 0.5);
			em += accent * vein * (0.9 + 0.5 * sin(TIME * 3.0 + uv.y * 20.0));
			r = 0.55; m = 0.05;
		} else if (pattern == 2) {
			vec2 s = vec2(uv.x * panels_u, uv.y * panels_v);
			s.x += step(1.0, mod(floor(s.y), 2.0)) * 0.5;
			vec2 f = fract(s) - vec2(0.5, 0.2);
			float sc = smoothstep(0.55, 0.35, length(f * vec2(1.0, 1.4)));
			col = mix(under, paint, sc);
			col *= 0.85 + 0.3 * f.y;
			em += accent * (1.0 - sc) * 0.25;
		} else if (pattern == 4) {
			float g = max(line_aa(uv.x * panels_u), line_aa(uv.y * panels_v));
			float sheen = 0.5 + 0.5 * sin(uv.x * 9.0 + uv.y * 7.0 + TIME * 0.8);
			col = mix(col, vec3(1.0, 0.95, 0.75), sheen * 0.25) * (1.0 - 0.5 * g);
			em += col * (0.25 + 0.25 * sheen);
		}
	}
	if (lights > 0.0) {
		float cx = fract(uv.x * light_count) - 0.5;
		float cy = (uv.y - light_v) / max(light_w, 0.001);
		float dotv = 1.0 - smoothstep(0.18, 0.32, length(vec2(cx, cy * 0.5)));
		float run = 0.55 + 0.45 * sin(TIME * (2.0 + chase * 10.0) - uv.x * 6.2831 * 4.0);
		em += accent * dotv * lights * run * 3.0;
		col = mix(col, accent, dotv * 0.6);
	}
	col = mix(col, flash_color, flash * 0.7);
	em += flash_color * flash * 1.5;
	ALBEDO = col;
	METALLIC = m;
	ROUGHNESS = r;
	EMISSION = em;
	RIM = rim_amt;
	RIM_TINT = 0.4;
	CLEARCOAT = coat;
	CLEARCOAT_ROUGHNESS = 0.08;
}
