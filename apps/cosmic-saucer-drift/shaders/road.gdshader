shader_type spatial;
// Track surface in HD. Vertex COLOR.rgb = surface tint, COLOR.a * 8 = surface id
// (0 metal, 1 dust, 2 ice, 3 magnetic rail, 4 moss, 5 lava rock).
// UV.x = across the road (0..1), UV.y = metres along / 8.
// detail: 0 = flat (low), 0.5 = textured, 1 = textured + bump + glints.
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec3 neon : source_color = vec3(0.3, 0.9, 1.0);
uniform float glow = 1.6;
uniform float detail = 1.0;
uniform float quality = 1.0;
uniform float metal_k = 1.0;   // lower without sky reflections

varying float sid;
varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) { return vnoise(p) * 0.55 + vnoise(p * 2.1) * 0.3 + vnoise(p * 4.3) * 0.15; }
// Cellular cracks: distance to the nearest cell edge.
float cells(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 17.0));
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return d2 - d1;
}

// Height field per surface, in road space (x across in metres, y along in metres).
float height(int s, vec2 r, vec2 w) {
	if (s == 0) {
		vec2 g = abs(fract(vec2(r.x / 2.0, r.y / 4.0)) - 0.5);
		float plate = smoothstep(0.5, 0.46, max(g.x, g.y));
		vec2 b = abs(fract(vec2(r.x / 2.0, r.y / 4.0) + 0.5) - 0.5) * vec2(2.0, 4.0);
		float bolt = 1.0 - smoothstep(0.06, 0.1, length(b - vec2(0.85, 1.85)));
		return plate * 0.6 + bolt * 0.4 + vnoise(vec2(r.x * 30.0, r.y * 2.0)) * 0.05;
	} else if (s == 1) {
		float rip = sin(dot(w, vec2(0.8, 0.6)) * 2.2 + fbm(w * 0.35) * 5.0) * 0.5 + 0.5;
		return rip * 0.5 + fbm(w * 3.0) * 0.35;
	} else if (s == 2) {
		return smoothstep(0.0, 0.08, cells(w * 0.45)) * 0.5 + vnoise(w * 6.0) * 0.1;
	} else if (s == 3) {
		float groove = abs(fract(r.x / 0.6) - 0.5);
		return smoothstep(0.1, 0.2, groove) * 0.4;
	} else if (s == 4) {
		return fbm(w * 1.4) * 0.8 + vnoise(w * 7.0) * 0.2;
	}
	return smoothstep(0.0, 0.1, cells(w * 0.3)) * 0.7 + fbm(w * 2.5) * 0.3;
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
	float along = v * 8.0;
	// Road space: 12 units across (6 plates of 2), metres along.
	vec2 rp = vec2(u * 12.0, along);
	vec2 wp = wpos.xz;
	float edge = 1.0 - smoothstep(0.0, 0.022, min(u, 1.0 - u));
	float dl = min(abs(u - 0.3333), abs(u - 0.6667));
	float dash = (1.0 - smoothstep(0.003, 0.008, dl)) * step(0.5, fract(v * 0.5));
	vec3 col = base;
	vec3 em = neon * (edge * 1.2 + dash * 0.5) * glow;
	float rough = 0.5;
	float metal = 0.5;
	float spec = 0.5;
	if (s == 0) {
		vec2 g = abs(fract(vec2(u * 6.0, v * 0.5)) - 0.5);
		float panel = smoothstep(0.46, 0.5, max(g.x, g.y));
		col = base * (1.05 - 0.3 * panel);
		if (detail > 0.25) {
			float tile = hash(floor(vec2(rp.x / 2.0, rp.y / 4.0)));
			col *= 0.9 + 0.2 * tile;
			col *= 0.92 + 0.08 * vnoise(vec2(rp.x * 30.0, rp.y * 2.0));
			float grime = fbm(wp * 0.3);
			col = mix(col, col * 0.6, smoothstep(0.55, 0.8, grime) * 0.6);
		}
		rough = 0.4; metal = 0.5;
	} else if (s == 1) {
		float n = vnoise(wp * 0.35) * 0.6 + vnoise(wp * 2.1) * 0.4;
		col = base * (0.7 + 0.45 * n);
		if (detail > 0.25) {
			float rip = sin(dot(wp, vec2(0.8, 0.6)) * 2.2 + fbm(wp * 0.35) * 5.0) * 0.5 + 0.5;
			col *= 0.88 + 0.22 * rip;
			col = mix(col, col * 0.7, smoothstep(0.6, 0.9, fbm(wp * 0.08)) * 0.5);
		}
		rough = 0.95; metal = 0.0; spec = 0.2;
		em *= 0.5;
	} else if (s == 2) {
		float streak = vnoise(vec2(u * 18.0, v * 0.6));
		col = mix(base, vec3(0.95, 0.98, 1.0), streak * 0.35);
		rough = 0.06; metal = 0.15; spec = 0.9;
		em += vec3(0.05, 0.12, 0.2) * streak;
		if (detail > 0.25) {
			float cr = 1.0 - smoothstep(0.0, 0.06, cells(wp * 0.45));
			col = mix(col, vec3(0.55, 0.8, 1.0), cr * 0.5);
			em += vec3(0.2, 0.55, 1.0) * cr * 0.35;
		}
	} else if (s == 3) {
		float chev = step(0.55, fract(v * 0.9 - abs(u - 0.5) * 1.6 - TIME * 1.8));
		float rails = 1.0 - smoothstep(0.004, 0.012, min(min(abs(u - 0.1667), abs(u - 0.5)), abs(u - 0.8333)));
		col = base;
		em = neon * (edge * 1.4 + rails * 1.6 + chev * 0.35) * glow;
		rough = 0.3; metal = 0.8;
	} else if (s == 4) {
		float spot = smoothstep(0.72, 0.8, vnoise(wp * 0.9));
		col = base * (0.75 + 0.4 * vnoise(wp * 3.0));
		if (detail > 0.25) {
			col *= 0.85 + 0.3 * fbm(wp * 1.4);
			float bloom = smoothstep(0.8, 0.86, vnoise(wp * 2.6 + 3.0));
			col = mix(col, vec3(1.0, 0.5, 0.9), bloom * 0.6);
			em += vec3(1.0, 0.4, 0.9) * bloom * 0.4;
		}
		em += vec3(0.2, 1.0, 0.7) * spot * 0.7;
		rough = 0.9; metal = 0.0; spec = 0.25;
	} else {
		float n = vnoise(wp * 0.5);
		float crack = 1.0 - smoothstep(0.0, 0.05, abs(n - 0.5));
		col = base * (0.8 + 0.3 * vnoise(wp * 2.5));
		float pulse = 0.9 + 0.3 * sin(TIME * 2.0 + wpos.x * 0.1);
		if (detail > 0.25) {
			float c2 = 1.0 - smoothstep(0.0, 0.07, cells(wp * 0.3));
			crack = max(crack, c2);
			col *= 0.8 + 0.35 * fbm(wp * 2.5);
		}
		em += vec3(1.0, 0.35, 0.05) * crack * pulse * 1.4;
		rough = 0.85; metal = 0.1; spec = 0.3;
	}
	// Kerbs: striped bands just inside the neon edges (not on rails).
	if (s != 3) {
		float kerb = step(min(u, 1.0 - u), 0.045) * (1.0 - edge);
		float stripe = step(0.5, fract(v * 4.0));
		vec3 kc = mix(vec3(0.92, 0.92, 0.96), neon * 0.85, stripe);
		col = mix(col, kc, kerb * 0.85);
		em += neon * kerb * stripe * 0.25;
		rough = mix(rough, 0.4, kerb);
	}
	// Bump detail with a derivative-based tangent frame (no mesh tangents needed).
	if (detail > 0.75) {
		float e = 0.05;
		float h0 = height(s, rp, wp);
		float hx = height(s, rp + vec2(e, 0.0), wp + vec2(e, 0.0));
		float hy = height(s, rp + vec2(0.0, e), wp + vec2(0.0, e));
		float k = 0.9;
		vec3 n_ts = normalize(vec3(-(hx - h0) / e * k * 0.12, -(hy - h0) / e * k * 0.12, 1.0));
		vec3 dp1 = dFdx(VERTEX);
		vec3 dp2 = dFdy(VERTEX);
		vec2 duv1 = dFdx(UV);
		vec2 duv2 = dFdy(UV);
		vec3 n = NORMAL;
		vec3 dp2perp = cross(dp2, n);
		vec3 dp1perp = cross(n, dp1);
		vec3 t = dp2perp * duv1.x + dp1perp * duv2.x;
		vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;
		float invmax = inversesqrt(max(max(dot(t, t), dot(b, b)), 1e-12));
		NORMAL = normalize(mat3(t * invmax, b * invmax, n) * n_ts);
		col *= 0.88 + 0.24 * h0;
		// Ice and metal glints.
		if (s == 2 || s == 0) {
			float gl = step(0.996, hash(floor(wp * 22.0))) * (0.5 + 0.5 * sin(TIME * 4.0 + hash(floor(wp * 22.0)) * 30.0));
			em += vec3(1.0) * gl * (s == 2 ? 1.6 : 0.5);
		}
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = metal * metal_k;
	SPECULAR = spec;
	EMISSION = em;
}
