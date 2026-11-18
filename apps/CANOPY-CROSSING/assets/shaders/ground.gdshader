shader_type canvas_item;
// Bird's-eye ground in high definition: turf, trade-road dirt and rock are
// shaded per pixel, so they stay sharp at any screen size. Grass has patchy
// tones, lit blades, clover and tiny flowers; dirt has grit, wheel ruts,
// pebbles with shadows, puddles when the jungle is wet and cracks when it is
// dry; rock has strata, cracks and moss. Rows meet along a ragged line (grass
// frays over the road, banks turn to wet soil at the water) and the canopy
// throws slow, soft light and shade over everything.
//
// Coordinates are world tiles (x right, y down the screen), so patches and
// shade run on across rows. `row` is this lane's row; `up` / `down` say what
// lies above and below: 0 nothing special, 1 water, 2 dirt, 3 grass.

uniform sampler2D n_soft : repeat_enable, filter_linear_mipmap;
uniform sampler2D n_fine : repeat_enable, filter_linear_mipmap;
uniform vec4 base : source_color = vec4(0.24, 0.6, 0.23, 1.0);
uniform vec4 alt : source_color = vec4(0.28, 0.66, 0.27, 1.0);
uniform vec4 soil : source_color = vec4(0.54, 0.42, 0.27, 1.0);
uniform vec4 accent : source_color = vec4(0.96, 0.83, 0.23, 1.0);
uniform vec4 col_up : source_color = vec4(0.24, 0.6, 0.23, 1.0);
uniform vec4 col_down : source_color = vec4(0.24, 0.6, 0.23, 1.0);
uniform int kind = 0;            // 0 grass, 1 dirt, 2 rock
uniform int up = 0;
uniform int down = 0;
uniform float row = 0.0;
uniform float tile = 80.0;
uniform float wet = 0.0;         // rain, steam, swamp: puddles, darker soil
uniform float moss = 0.0;        // mist: moss on stones, more clover
uniform float dry = 0.0;         // dust: cracks, paler soil, straw in the grass
uniform float dapple = 0.5;      // canopy light and shade
uniform float fine = 1.0;        // 1 High, lower on Medium
uniform float sway = 1.0;        // 0 with Reduce motion
uniform float tone = 1.0;        // overall brightness (ridges are darker)

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash2(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

vec2 rot(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

// A stone seen from above: body, lit upper left, shaded lower right, a soft
// shadow on the ground. Returns the colour to show (rgb) and its cover (a).
vec4 stone(vec2 d, vec2 rad, vec3 c, float aa) {
	float e = length(d / rad);
	float body = smoothstep(1.0 + aa, 1.0 - aa, e);
	float lit = clamp(0.92 - (d.x / rad.x + d.y / rad.y) * 0.34, 0.55, 1.3);
	float spec = smoothstep(0.42, 0.1, length((d + rad * vec2(0.3, 0.34)) / rad));
	vec3 col = c * lit + vec3(0.16) * spec;
	col *= 1.0 - 0.3 * smoothstep(0.62, 1.0, e);
	return vec4(col, body);
}

vec3 grass(vec2 wp, vec3 a, vec3 b) {
	float m = texture(n_soft, wp * 0.115).r;
	float m2 = texture(n_soft, wp * 0.47 + vec2(0.37, 0.11)).r;
	vec3 col = mix(a, b, smoothstep(0.36, 0.64, m));
	col *= 0.86 + 0.28 * m2;
	// straw where the ground is dry, deeper green where it is wet
	col = mix(col, col * vec3(1.18, 1.08, 0.72), dry * smoothstep(0.45, 0.75, m2) * 0.6);
	col = mix(col, col * vec3(0.82, 0.94, 0.86), wet * 0.35);
	// blades: fine streaks lit from the upper left
	vec2 buv = wp * vec2(0.55, 0.16);
	float b0 = texture(n_fine, buv).r;
	float b1 = texture(n_fine, buv + vec2(0.006, 0.004)).r;
	col *= 1.0 + (b0 - 0.5) * 0.16 * fine;
	col += (b0 - b1) * 0.7 * fine * vec3(0.9, 1.0, 0.6);
	// small plants, one to a cell: flowers, clover, a pale tuft (High only;
	// the row's decoration mesh carries plants on every setting)
	if (fine < 0.9) {
		return col;
	}
	vec2 g = wp * 3.0;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id);
	vec2 d = f - (hash2(id) - 0.5) * 0.46;
	float aa = fwidth(g.x) * 1.2;
	float r = length(d);
	if (h < 0.085) {
		float ang = atan(d.y, d.x);
		float petal = 0.085 + 0.04 * cos(ang * 5.0 + h * 90.0);
		float fl = smoothstep(petal + aa, petal - aa, r);
		vec3 pc = mix(accent.rgb, vec3(1.0, 0.98, 0.94), step(0.045, h) * 0.75);
		col = mix(col, col * 0.72, smoothstep(0.2, 0.06, length(d - vec2(0.03, 0.05))) * 0.5);
		col = mix(col, pc * (0.86 + 0.2 * cos(ang * 5.0 + h * 90.0)), fl);
		col = mix(col, vec3(0.99, 0.78, 0.18), smoothstep(0.034 + aa, 0.034 - aa, r));
	} else if (h < 0.2 + moss * 0.14) {
		// clover: three round leaflets with a pale centre mark
		float lf = 0.0;
		float mark = 0.0;
		for (int i = 0; i < 3; i++) {
			vec2 q = d - rot(vec2(0.075, 0.0), h * 60.0 + float(i) * 2.094);
			float lr = length(q);
			lf = max(lf, smoothstep(0.07 + aa, 0.07 - aa, lr));
			mark = max(mark, smoothstep(0.035, 0.015, lr));
		}
		vec3 cc = mix(a, b, 0.5) * vec3(0.74, 0.96, 0.74);
		col = mix(col, cc, lf * 0.92);
		col = mix(col, cc * 1.28, mark * lf * 0.7);
	} else if (h < 0.36) {
		// a pale tuft catching the light: a few short strokes fanned upward
		float st = 0.0;
		for (int i = 0; i < 4; i++) {
			float lean = (float(i) - 1.5) * 0.34 + (h - 0.28) * 2.0;
			vec2 q = rot(d + vec2(0.0, -0.06), lean);
			float w = 0.014 * (1.0 - clamp(-q.y / 0.2, 0.0, 1.0)) + 0.004;
			st = max(st, smoothstep(w + aa, w - aa, abs(q.x)) * step(-0.2, q.y) * step(q.y, 0.0));
		}
		col = mix(col, b * vec3(1.22, 1.24, 0.92), st * 0.75);
	}
	return col;
}

vec3 dirt(vec2 wp, vec2 p, vec3 a, vec3 b) {
	float m = texture(n_soft, wp * 0.13 + vec2(0.61, 0.23)).r;
	float m2 = texture(n_soft, wp * 0.61 + vec2(0.2, 0.7)).r;
	vec3 col = mix(a, b, smoothstep(0.34, 0.66, m));
	col *= 0.84 + 0.32 * m2;
	col = mix(col, col * vec3(1.14, 1.1, 0.98), dry * 0.5);
	col = mix(col, col * vec3(0.74, 0.76, 0.8), wet * 0.45);
	// grit, lit from the upper left
	vec2 guv = wp * 0.6;
	float g0 = texture(n_fine, guv).r;
	float g1 = texture(n_fine, guv + vec2(0.005, 0.005)).r;
	col *= 1.0 + (g0 - 0.5) * 0.22 * fine;
	col += (g0 - g1) * 0.8 * fine;
	// two wheel ruts with a tread pattern pressed into them
	float off = abs(abs(p.y) - 0.22) + (m2 - 0.5) * 0.05;
	float rut = smoothstep(0.085, 0.03, off);
	float tread = 0.5 + 0.5 * sin(wp.x * 44.0 + sign(p.y) * 1.3 + abs(p.y) * 60.0);
	col *= 1.0 - rut * (0.2 + 0.12 * tread * fine);
	col *= 1.0 + smoothstep(0.03, 0.0, abs(off - 0.11)) * 0.1;
	// puddles when wet: dark, with a moving glint of sky
	float pd = smoothstep(0.66, 0.72, texture(n_soft, wp * 0.29 + vec2(0.9, 0.4)).r + wet * 0.2 - 0.14) * step(0.05, wet);
	float gl = texture(n_soft, wp * 1.1 + vec2(TIME * 0.025 * sway, 0.0)).r;
	col = mix(col, col * 0.55 + vec3(0.05, 0.08, 0.1), pd * 0.85);
	col += vec3(0.3, 0.36, 0.38) * smoothstep(0.56, 0.74, gl) * pd * 0.6;
	// cracks when dry: thin dark lines where the fine noise folds
	float cr = abs(texture(n_soft, wp * 0.9 + vec2(0.3, 0.8)).r - 0.5);
	col *= 1.0 - smoothstep(0.022, 0.004, cr) * 0.4 * dry;
	// pebbles, one to a cell (High only)
	vec2 g = wp * 4.0;
	vec2 id = floor(g);
	float h = hash(id + 11.0);
	float aa = fwidth(g.x) * 9.0;
	if (h < 0.34 && fine > 0.9) {
		vec2 f = fract(g) - 0.5;
		vec2 hh = hash2(id + 5.0);
		vec2 d = rot(f - (hh - 0.5) * 0.4, h * 40.0);
		vec2 rad = vec2(0.09 + 0.1 * hh.x, 0.065 + 0.06 * hh.y) * (0.75 + 0.6 * step(h, 0.06));
		float sh = smoothstep(1.35, 0.7, length((d - rad * 0.3) / rad));
		col *= 1.0 - sh * 0.3;
		vec3 sc = mix(vec3(0.5, 0.49, 0.46), vec3(0.74, 0.7, 0.62), hh.y);
		sc = mix(sc, a, 0.3) * (1.0 - wet * 0.22);
		sc = mix(sc, vec3(0.36, 0.5, 0.26), moss * step(0.5, hh.x) * 0.55);
		vec4 s = stone(d, rad, sc, aa);
		col = mix(col, s.rgb, s.a * (1.0 - pd * 0.5));
	}
	return col;
}

vec3 rock(vec2 wp, vec3 a, vec3 b) {
	float m = texture(n_soft, wp * 0.21 + vec2(0.4, 0.8)).r;
	float m2 = texture(n_soft, wp * vec2(0.33, 1.3) + vec2(0.1, 0.5)).r;
	vec3 col = mix(a, b, smoothstep(0.3, 0.7, m));
	col *= 0.78 + 0.4 * m2;
	float g0 = texture(n_fine, wp * 0.6).r;
	float g1 = texture(n_fine, wp * 0.6 + vec2(0.005, 0.005)).r;
	col *= 1.0 + (g0 - 0.5) * 0.3 * fine;
	col += (g0 - g1) * 1.4 * fine;
	float cr = abs(texture(n_soft, wp * 0.74 + vec2(0.7, 0.2)).r - 0.5);
	col *= 1.0 - smoothstep(0.02, 0.003, cr) * 0.5;
	float ms = smoothstep(0.58 - moss * 0.2, 0.7 - moss * 0.2, texture(n_soft, wp * 0.5 + vec2(0.2, 0.3)).r);
	col = mix(col, vec3(0.3, 0.5, 0.24) * (0.8 + 0.5 * g0), ms * 0.7);
	return col;
}

vec3 surface(int k, vec2 wp, vec2 p, vec3 a, vec3 b) {
	if (k == 1) {
		return dirt(wp, p, a, b);
	}
	if (k == 2) {
		return rock(wp, a, b);
	}
	return grass(wp, a, b);
}

// What this row shows where the neighbour reaches into it.
vec3 neighbour(int what, vec2 wp, vec3 c) {
	float m = texture(n_soft, wp * 0.47 + vec2(0.37, 0.11)).r;
	float b0 = texture(n_fine, wp * vec2(0.55, 0.16)).r;
	if (what == 2) {
		return c * (0.86 + 0.3 * m) * (1.0 + (b0 - 0.5) * 0.25);
	}
	return c * (0.84 + 0.3 * m) * (1.0 + (b0 - 0.5) * 0.2);
}

void fragment() {
	vec2 p = lp / tile;
	vec2 wp = vec2(p.x, p.y - row);
	vec3 col = surface(kind, wp, p, base.rgb, alt.rgb) * tone;
	float e_up = p.y + 0.5;
	float e_dn = 0.5 - p.y;
	// one wavy line per boundary, shared by the two rows that meet there
	float j_up = (texture(n_fine, vec2(wp.x * 0.37, (row + 1.0) * 0.37)).r - 0.5) * 0.2
		+ (texture(n_soft, vec2(wp.x * 0.9, (row + 1.0) * 0.21)).r - 0.5) * 0.12;
	float j_dn = (texture(n_fine, vec2(wp.x * 0.37, row * 0.37)).r - 0.5) * 0.2
		+ (texture(n_soft, vec2(wp.x * 0.9, row * 0.21)).r - 0.5) * 0.12;
	float aa = fwidth(p.y) * 1.5;
	if (kind == 0) {
		// a bank of wet soil at the water, with pebbles of light on its lip
		if (up == 1) {
			float bank = smoothstep(0.15 + j_up + aa, 0.15 + j_up - aa, e_up);
			vec3 mud = soil.rgb * (0.62 + 0.3 * texture(n_soft, wp * 0.8).r) * (0.9 + 0.3 * texture(n_fine, wp * 0.7).r);
			col = mix(col, col * 0.72, smoothstep(0.26 + j_up, 0.15 + j_up, e_up) * 0.6);
			col = mix(col, mud, bank);
			col *= 1.0 - 0.4 * smoothstep(0.06, 0.0, e_up);
		}
		if (down == 1) {
			float bank = smoothstep(0.1 - j_dn + aa, 0.1 - j_dn - aa, e_dn);
			vec3 mud = soil.rgb * (0.6 + 0.3 * texture(n_soft, wp * 0.8).r) * (0.9 + 0.3 * texture(n_fine, wp * 0.7).r);
			col = mix(col, col * 0.72, smoothstep(0.2 - j_dn, 0.1 - j_dn, e_dn) * 0.6);
			col = mix(col, mud, bank);
			col *= 1.0 - 0.45 * smoothstep(0.05, 0.0, e_dn);
		}
		// two tones of grass meet along the wavy line
		if (up == 3) {
			col = mix(col, neighbour(3, wp, col_up.rgb) * tone, smoothstep(j_up * 0.6 + aa, j_up * 0.6 - aa, e_up));
		}
		if (down == 3) {
			col = mix(col, neighbour(3, wp, col_down.rgb) * tone, smoothstep(-j_dn * 0.6 + aa, -j_dn * 0.6 - aa, e_dn));
		}
		// the turf stands a little above the road: a lit edge above, a shaded one below
		if (up == 2) {
			col *= 1.0 + 0.1 * smoothstep(0.07, 0.0, e_up);
		}
		if (down == 2) {
			col *= 1.0 - 0.22 * smoothstep(0.09, 0.0, e_dn);
		}
	} else if (kind == 1) {
		// grass frays over the edge of the road and shades the dirt beside it
		if (up == 3) {
			float reach = 0.1 + j_up * 0.9;
			col *= 1.0 - 0.3 * smoothstep(reach + 0.1, reach, e_up);
			col = mix(col, neighbour(3, wp, col_up.rgb), smoothstep(reach + aa, reach - aa, e_up));
		}
		if (down == 3) {
			float reach = 0.1 - j_dn * 0.9;
			col *= 1.0 - 0.18 * smoothstep(reach + 0.07, reach, e_dn);
			col = mix(col, neighbour(3, wp, col_down.rgb), smoothstep(reach + aa, reach - aa, e_dn));
		}
		if (up == 1) {
			col *= 1.0 - 0.45 * smoothstep(0.14 + j_up, 0.0, e_up);
		}
		if (down == 1) {
			col *= 1.0 - 0.45 * smoothstep(0.12 - j_dn, 0.0, e_dn);
		}
	} else {
		if (up == 1) {
			col *= 1.0 - 0.4 * smoothstep(0.12, 0.0, e_up);
		}
		if (down == 1) {
			col *= 1.0 - 0.4 * smoothstep(0.1, 0.0, e_dn);
		}
	}
	// the canopy's light and shade drift slowly over the floor
	if (dapple > 0.0) {
		vec2 dv = wp * 0.19 + vec2(TIME * 0.006, TIME * 0.004) * sway;
		float sh = texture(n_soft, dv).r;
		float sh2 = texture(n_soft, wp * 0.33 - vec2(TIME * 0.008, 0.0) * sway + vec2(0.5, 0.2)).r;
		float shade = smoothstep(0.42, 0.62, sh * 0.6 + sh2 * 0.4);
		col *= mix(1.0, 0.8 + 0.3 * shade, dapple);
		col += vec3(0.12, 0.11, 0.05) * smoothstep(0.66, 0.78, sh2) * shade * dapple;
	}
	COLOR = vec4(col, 1.0);
}
