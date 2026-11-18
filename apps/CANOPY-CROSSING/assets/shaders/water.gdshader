shader_type canvas_item;
// River / swamp surface for the bird's-eye view, in high definition: you see
// the stony bed through the shallows, a net of light (caustics) playing over
// it, ripples lit from the upper left, flecks of sun, streaks that drift with
// the current, and foam lapping at each bank. Where the next row is water
// too the river simply runs on, with no bank between.
// `lt` is the lane's own clock (follows slow-motion and pause), `flow` its
// current in tiles per second, `tile` the tile size in pixels. `up` / `down`:
// 1 when the row above / below is water. Coordinates are world tiles.

uniform sampler2D n_soft : repeat_enable, filter_linear_mipmap;
uniform sampler2D n_fine : repeat_enable, filter_linear_mipmap;
uniform vec4 base : source_color = vec4(0.18, 0.55, 0.62, 1.0);
uniform vec4 deep : source_color = vec4(0.08, 0.32, 0.4, 1.0);
uniform vec4 foam : source_color = vec4(0.85, 0.95, 0.95, 1.0);
uniform vec4 bed : source_color = vec4(0.54, 0.42, 0.27, 1.0);
uniform float flow = 0.4;
uniform float lt = 0.0;
uniform float tile = 80.0;
uniform float glints = 1.0;
uniform float row = 0.0;
uniform int up = 0;
uniform int down = 0;
uniform float murk = 0.0;        // swamp water hides its bed
uniform float rapids = 0.0;      // fast water: more white
uniform float fine = 1.0;

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

void fragment() {
	vec2 p = lp / tile;
	vec2 wp = vec2(p.x, p.y - row);
	vec2 fp = vec2(wp.x - lt * flow, wp.y);          // rides the current
	float e_up = p.y + 0.5;
	float e_dn = 0.5 - p.y;
	float d_up = up == 1 ? 1.0 : e_up;
	float d_dn = down == 1 ? 1.0 : e_dn;
	float sd = min(d_up, d_dn);                      // distance to the nearest bank
	// slow swell that bends everything seen through or on the water
	vec2 sw = vec2(texture(n_soft, fp * 0.31 + vec2(0.0, lt * 0.03)).r,
		texture(n_soft, fp * 0.31 + vec2(0.47, -lt * 0.04)).r) - 0.5;
	// depth: the far side of each row lies in shade, the banks are shallow
	float d = smoothstep(-0.5, 0.45, p.y);
	float shallow = 1.0 - smoothstep(0.0, 0.42, sd);
	vec3 col = mix(deep.rgb, base.rgb, 0.3 + 0.7 * d);
	col *= 0.94 + 0.12 * texture(n_soft, wp * 0.23 + sw * 0.1, 1.0).r;
	// murky swamp water: tea-brown and green, not grey
	col = mix(col, col * vec3(0.95, 1.08, 0.86) + vec3(0.02, 0.03, 0.0), murk * 0.6);
	// the bed: stones seen through the water, clearest in the shallows
	float see = (0.16 + 0.5 * shallow) * (1.0 - murk * 0.85);
	vec2 bp = wp + sw * 0.07;
	vec2 g = bp * 3.4;
	vec2 id = floor(g);
	float h = hash(id + 3.0);
	float aa = fwidth(g.x) * 8.0;
	vec3 floor_c = mix(deep.rgb, bed.rgb, 0.45) * (0.8 + 0.3 * texture(n_soft, bp * 0.7).r);
	if (h < 0.55) {
		vec2 hh = hash2(id + 9.0);
		vec2 q = fract(g) - 0.5 - (hh - 0.5) * 0.36;
		vec2 rad = vec2(0.12 + 0.13 * hh.x, 0.09 + 0.1 * hh.y);
		float e = length(q / rad);
		float st = smoothstep(1.0 + aa, 1.0 - aa, e);
		vec3 sc = mix(vec3(0.42, 0.44, 0.42), vec3(0.66, 0.62, 0.52), hh.y) * clamp(0.95 - (q.x / rad.x + q.y / rad.y) * 0.3, 0.6, 1.25);
		floor_c *= 1.0 - 0.35 * smoothstep(1.5, 0.9, length((q - rad * 0.3) / rad)) * (1.0 - st);
		floor_c = mix(floor_c, mix(sc, base.rgb, 0.35), st);
	}
	col = mix(col, floor_c * mix(vec3(1.0), base.rgb * 1.6, 0.4), see);
	// caustics: a bright, shifting net where two swells cross
	float c1 = texture(n_soft, fp * 0.83 + sw * 0.25 + vec2(0.0, lt * 0.05)).r;
	float c2 = texture(n_soft, fp * 1.07 - sw * 0.2 + vec2(0.31, -lt * 0.06)).r;
	float net = smoothstep(0.03, 0.0, abs(c1 - c2));
	col += foam.rgb * net * (0.05 + 0.12 * shallow) * (1.0 - murk * 0.7) * glints;
	// ripples lit from the upper left
	// broad swells across the current, then a faint fine chop on top
	vec2 ruv = fp * vec2(0.36, 1.0) + sw * 0.25 + vec2(0.0, lt * 0.03);
	float r0 = texture(n_soft, ruv, 1.5).r;
	float r1 = texture(n_soft, ruv + vec2(0.014, 0.02), 1.5).r;
	col *= 1.0 + (r0 - 0.5) * 0.1;
	col += (r0 - r1) * 1.1 * vec3(0.8, 0.95, 1.0);
	float r2 = texture(n_fine, fp * vec2(0.12, 0.3) + sw * 0.1 + vec2(0.0, lt * 0.02), 1.0).r;
	col *= 1.0 + (r2 - 0.5) * 0.04 * fine;
	// streaks that drift with the current
	float st2 = texture(n_fine, vec2(fp.x * 0.07, wp.y * 1.1 + sw.x * 0.2)).r;
	col = mix(col, foam.rgb, smoothstep(0.64 - rapids * 0.07, 0.76, st2) * (0.12 + 0.3 * rapids));
	// flecks of sun
	float sp = texture(n_fine, fp * 0.5 + vec2(lt * 0.03, lt * 0.05)).r * texture(n_soft, fp * 0.6 - vec2(lt * 0.04, 0.0)).r;
	col = mix(col, vec3(1.0), smoothstep(0.47, 0.56, sp) * 0.4 * glints * (1.0 - murk * 0.7));
	// the banks: shade under the far one, foam lapping at both
	float wob = (texture(n_soft, vec2(wp.x * 0.7, row * 0.3 + lt * 0.05)).r - 0.5) * 0.09 + sin(lt * 1.4 + wp.x * 5.0) * 0.012;
	float bub = 0.55 + 0.75 * texture(n_fine, wp * 1.3 + vec2(lt * 0.04, 0.0)).r;
	if (up != 1) {
		col *= 1.0 - 0.42 * smoothstep(0.26, 0.0, e_up);
		float f = smoothstep(0.07 + wob, 0.02 + wob, e_up);
		col = mix(col, foam.rgb * bub, f * 0.75);
		col = mix(col, foam.rgb, smoothstep(0.02, 0.0, abs(e_up - 0.11 - wob * 1.4)) * 0.3);
	}
	if (down != 1) {
		float f = smoothstep(0.08 - wob, 0.025 - wob, e_dn);
		col = mix(col, foam.rgb * bub, f * 0.85);
		col = mix(col, foam.rgb, smoothstep(0.02, 0.0, abs(e_dn - 0.13 + wob * 1.4)) * 0.35);
	}
	COLOR = vec4(col, 1.0);
}
