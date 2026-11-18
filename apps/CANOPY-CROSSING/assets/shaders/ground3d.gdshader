shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// First-person ground in high definition, shaded per pixel in world space so
// it stays sharp right up to the animal's nose:
//   grass  patchy turf, fine blades, clover and small flowers, real bumps
//   dirt   a trade road: grit, two wheel ruts, pebbles, puddles that mirror
//          the light when wet, cracks when dry
//   forest the floor under the canopy: brown litter of fallen leaves, twigs,
//          moss and the odd flower
//   rock   a waterfall's lip: strata, cracks, moss
// The sides of each row (seen at a river's edge) are banks of layered soil.
// One unit is one tile; rows run along x, the row number is -z.

uniform sampler2D n_soft : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D n_fine : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 base : source_color = vec4(0.24, 0.6, 0.23, 1.0);
uniform vec4 alt : source_color = vec4(0.28, 0.66, 0.27, 1.0);
uniform vec4 soil : source_color = vec4(0.54, 0.42, 0.27, 1.0);
uniform vec4 accent : source_color = vec4(0.96, 0.83, 0.23, 1.0);
uniform vec4 leaf : source_color = vec4(0.12, 0.35, 0.16, 1.0);
uniform int kind = 0;            // 0 grass, 1 dirt, 2 forest floor, 3 rock
uniform float wet = 0.0;
uniform float moss = 0.0;
uniform float dry = 0.0;
uniform float hq = 1.0;          // 1 High: bumps and small details; 0 Medium

varying vec3 wp;
varying vec3 wn;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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

void fragment() {
	vec2 q = vec2(wp.x, -wp.z);
	float yl = q.y - floor(q.y + 0.5);          // -0.5 .. 0.5 across this row
	float far_fade = 1.0 - smoothstep(0.02, 0.08, fwidth(q.x));   // small things fade with distance
	vec3 col;
	float h = 0.0;                               // height for the bumps
	float rough = 0.92;
	float spec = 0.3;
	if (wn.y < 0.5) {
		// a bank of layered soil with roots and stones
		float layer = texture(n_soft, vec2(q.x * 0.6, wp.y * 6.0)).r;
		col = soil.rgb * (0.55 + 0.45 * layer) * (0.85 + 0.3 * texture(n_fine, vec2(q.x, wp.y) * 1.3).r);
		col = mix(col, col * 0.6, smoothstep(-0.05, -0.25, wp.y));
		col = mix(col, vec3(0.28, 0.42, 0.2), smoothstep(-0.05, 0.0, wp.y) * 0.5);
		ALBEDO = col;
		ROUGHNESS = 0.95;
		SPECULAR = 0.2;
	} else {
		float m = texture(n_soft, q * 0.23).r;
		float m2 = texture(n_soft, q * 0.9 + vec2(0.37, 0.11)).r;
		float f0 = texture(n_fine, q * 1.6).r;
		if (kind == 0) {
			col = mix(base.rgb, alt.rgb, smoothstep(0.36, 0.64, m));
			col *= 0.84 + 0.3 * m2;
			col = mix(col, col * vec3(1.18, 1.08, 0.72), dry * smoothstep(0.45, 0.75, m2) * 0.6);
			col = mix(col, col * vec3(0.82, 0.94, 0.86), wet * 0.3);
			float b0 = texture(n_fine, q * vec2(4.2, 4.6)).r;
			col *= 0.88 + 0.26 * b0;
			col += vec3(0.04, 0.06, 0.0) * smoothstep(0.6, 0.85, b0);
			// close up: the fine weave of blades, lit tips over shaded roots
			float b2 = texture(n_fine, q * vec2(13.0, 15.0)).r;
			col *= 0.9 + 0.22 * b2 * hq;
			col += vec3(0.05, 0.07, 0.01) * smoothstep(0.66, 0.86, b2) * hq;
			h = b0 * 0.6 + f0 * 0.4;
			if (hq > 0.5) {
				vec2 g = q * 5.0;
				vec2 id = floor(g);
				float hh = hash(id);
				vec2 d = fract(g) - 0.5 - (hash2(id) - 0.5) * 0.46;
				float r = length(d);
				float aa = fwidth(g.x) * 1.2;
				if (hh < 0.06) {
					float ang = atan(d.y, d.x);
					float petal = 0.09 + 0.045 * cos(ang * 5.0 + hh * 90.0);
					float fl = smoothstep(petal + aa, petal - aa, r) * far_fade;
					vec3 pc = mix(accent.rgb, vec3(1.0, 0.98, 0.94), step(0.03, hh) * 0.75);
					col = mix(col, pc, fl);
					col = mix(col, vec3(0.99, 0.78, 0.18), smoothstep(0.035 + aa, 0.035 - aa, r) * far_fade);
					h += fl * 0.6;
				} else if (hh < 0.18 + moss * 0.12) {
					float lf = 0.0;
					for (int i = 0; i < 3; i++) {
						vec2 o = d - rot(vec2(0.08, 0.0), hh * 60.0 + float(i) * 2.094);
						lf = max(lf, smoothstep(0.075 + aa, 0.075 - aa, length(o)));
					}
					col = mix(col, mix(base.rgb, alt.rgb, 0.5) * vec3(0.74, 0.98, 0.74), lf * 0.9 * far_fade);
					h += lf * 0.3;
				}
			}
			rough = 0.9;
		} else if (kind == 1) {
			col = mix(base.rgb, alt.rgb, smoothstep(0.34, 0.66, m));
			col *= 0.82 + 0.34 * m2;
			col = mix(col, col * vec3(1.14, 1.1, 0.98), dry * 0.5);
			col = mix(col, col * vec3(0.72, 0.74, 0.78), wet * 0.45);
			float g0 = texture(n_fine, q * 3.0).r;
			col *= 0.86 + 0.28 * g0;
			h = g0;
			// two wheel ruts with tread marks
			float off = abs(abs(yl) - 0.22) + (m2 - 0.5) * 0.05;
			float rut = smoothstep(0.085, 0.03, off);
			float tread = 0.5 + 0.5 * sin(q.x * 44.0 + sign(yl) * 1.3);
			col *= 1.0 - rut * (0.22 + 0.12 * tread * hq);
			h -= rut * 0.8;
			// puddles in the ruts and hollows when wet
			float pd = smoothstep(0.62, 0.7, texture(n_soft, q * 0.55 + vec2(0.9, 0.4)).r + rut * 0.15 + wet * 0.2 - 0.14) * step(0.05, wet);
			col = mix(col, col * 0.4 + vec3(0.03, 0.05, 0.06), pd * 0.85);
			rough = mix(0.95, 0.08, pd);
			spec = mix(0.3, 0.7, pd);
			h = mix(h, 0.0, pd);
			float cr = abs(texture(n_soft, q * 1.8 + vec2(0.3, 0.8)).r - 0.5);
			col *= 1.0 - smoothstep(0.02, 0.004, cr) * 0.45 * dry;
			if (hq > 0.5) {
				vec2 g = q * 6.0;
				vec2 id = floor(g);
				float hh = hash(id + 11.0);
				if (hh < 0.3) {
					vec2 hv = hash2(id + 5.0);
					vec2 d = rot(fract(g) - 0.5 - (hv - 0.5) * 0.4, hh * 40.0);
					vec2 rad = vec2(0.1 + 0.12 * hv.x, 0.08 + 0.08 * hv.y);
					float e = length(d / rad);
					float aa = fwidth(g.x) * 6.0;
					float st = smoothstep(1.0 + aa, 1.0 - aa, e) * far_fade * (1.0 - pd);
					vec3 sc = mix(vec3(0.48, 0.47, 0.44), vec3(0.74, 0.7, 0.62), hv.y);
					sc = mix(sc, vec3(0.36, 0.5, 0.26), moss * step(0.5, hv.x) * 0.55);
					col *= 1.0 - smoothstep(1.4, 0.9, e) * 0.25 * far_fade;
					col = mix(col, sc * (1.05 - 0.25 * e), st);
					h += st * (1.0 - e * e) * 1.4;
				}
			}
		} else if (kind == 2) {
			// forest floor: brown litter, darker hollows, moss
			col = mix(base.rgb, alt.rgb, smoothstep(0.3, 0.7, m)) * (0.8 + 0.35 * m2);
			float ms = smoothstep(0.55 - moss * 0.2, 0.7 - moss * 0.2, texture(n_soft, q * 0.7 + vec2(0.2, 0.3)).r);
			col = mix(col, leaf.rgb * vec3(0.9, 1.15, 0.8) * (0.8 + 0.4 * f0), ms * 0.6);
			h = f0;
			if (hq > 0.5) {
				// fallen leaves in two layers, each in its own colour and turn
				for (int layer = 0; layer < 2; layer++) {
					vec2 g = q * (4.0 + float(layer) * 2.3) + float(layer) * 7.1;
					vec2 id = floor(g);
					float hh = hash(id + 3.0 + float(layer) * 19.0);
					if (hh < 0.46) {
						vec2 hv = hash2(id + 1.0);
						vec2 d = rot(fract(g) - 0.5 - (hv - 0.5) * 0.3, hh * 31.0);
						float w = 0.17 * (1.0 - pow(abs(d.x) / 0.36, 2.0));
						float aa = fwidth(g.x) * 1.5;
						float lf = smoothstep(w + aa, w - aa, abs(d.y)) * step(abs(d.x), 0.36) * far_fade;
						vec3 lc = mix(vec3(0.46, 0.33, 0.17), vec3(0.32, 0.22, 0.12), hv.x);
						lc = mix(lc, vec3(0.58, 0.47, 0.22), step(0.82, hv.y));
						lc = mix(lc, leaf.rgb * 1.1, step(0.88, hh / 0.46) * 0.6);
						lc = mix(lc, base.rgb, 0.18);
						lc *= 0.9 + 0.2 * sign(d.y);
						lc *= 1.0 - smoothstep(0.012, 0.0, abs(d.y)) * 0.35;      // midrib
						col = mix(col * (1.0 - lf * 0.25), lc, lf * 0.92);
						h += lf * 0.35;
					}
				}
			}
			rough = 0.95;
		} else {
			col = mix(base.rgb, alt.rgb, smoothstep(0.3, 0.7, m)) * (0.75 + 0.45 * texture(n_soft, q * vec2(0.6, 2.4)).r);
			float cr = abs(texture(n_soft, q * 1.5 + vec2(0.7, 0.2)).r - 0.5);
			col *= 1.0 - smoothstep(0.02, 0.003, cr) * 0.5;
			float ms = smoothstep(0.58 - moss * 0.2, 0.7 - moss * 0.2, texture(n_soft, q * 0.9).r);
			col = mix(col, vec3(0.3, 0.5, 0.24) * (0.8 + 0.5 * f0), ms * 0.7);
			h = f0 - smoothstep(0.02, 0.003, cr);
			rough = mix(0.7, 0.4, wet);
		}
		// soft shade where one row meets the next
		col *= 1.0 - 0.12 * smoothstep(0.42, 0.5, abs(yl));
		ALBEDO = col;
		ROUGHNESS = rough;
		SPECULAR = spec;
		if (hq > 0.5) {
			// bumps: the height field's slope tilts the normal
			float s = 0.06;
			float hx = texture(n_fine, (q + vec2(s, 0.0)) * 1.6).r - f0;
			float hz = texture(n_fine, (q + vec2(0.0, s)) * 1.6).r - f0;
			float k = (kind == 3 ? 2.2 : 1.4) * far_fade + 0.4;
			vec3 nw = normalize(vec3(-hx * k, 1.0, hz * k));
			NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
		}
	}
}
