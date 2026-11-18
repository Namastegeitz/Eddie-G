shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// First-person river and swamp water in high definition: swells and a fine
// chop that drift with the current and catch the sun, the sky mirrored at
// low angles (Fresnel), the stony bed seen through the shallows, streaks of
// foam in fast water and a lapping line of foam at each bank. `lt` is the
// view's clock; `flow` the current in tiles a second (signed); `up` / `down`
// are 1 when the row beyond / nearer is water too (then there is no bank).

uniform sampler2D n_soft : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D n_fine : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 base : source_color = vec4(0.18, 0.55, 0.62, 1.0);
uniform vec4 deep : source_color = vec4(0.08, 0.32, 0.4, 1.0);
uniform vec4 foam : source_color = vec4(0.85, 0.95, 0.95, 1.0);
uniform vec4 bed : source_color = vec4(0.54, 0.42, 0.27, 1.0);
uniform vec4 sky : source_color = vec4(0.6, 0.78, 0.85, 1.0);
uniform float flow = 0.4;
uniform float lt = 0.0;
uniform int up = 0;
uniform int down = 0;
uniform float murk = 0.0;
uniform float rapids = 0.0;
uniform float hq = 1.0;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 q = vec2(wp.x, -wp.z);
	float yl = q.y - floor(q.y + 0.5);
	vec2 fq = vec2(q.x - lt * flow, q.y);
	// the surface: broad swells plus a fine chop, as a normal
	float s = 0.05;
	vec2 a = fq * vec2(0.7, 1.4) + vec2(0.0, lt * 0.05);
	float h0 = texture(n_soft, a).r;
	float hx = texture(n_soft, a + vec2(s, 0.0)).r - h0;
	float hz = texture(n_soft, a + vec2(0.0, s)).r - h0;
	vec3 nw = vec3(-hx * 5.0, 1.0, hz * 5.0);
	if (hq > 0.5) {
		vec2 b = fq * vec2(2.6, 3.4) + vec2(lt * 0.07, -lt * 0.05);
		float c0 = texture(n_fine, b).r;
		float cx = texture(n_fine, b + vec2(s, 0.0)).r - c0;
		float cz = texture(n_fine, b + vec2(0.0, s)).r - c0;
		nw += vec3(-cx * (1.6 + rapids * 1.6), 0.0, cz * (1.6 + rapids * 1.6));
	}
	nw = normalize(nw);
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	// distance to a bank (a row that is not water)
	float d_up = up == 1 ? 1.0 : 0.5 - yl;
	float d_dn = down == 1 ? 1.0 : yl + 0.5;
	float sd = min(d_up, d_dn);
	float shallow = 1.0 - smoothstep(0.0, 0.35, sd);
	vec3 col = mix(deep.rgb, base.rgb, 0.45 + 0.35 * h0);
	col = mix(col, col * vec3(0.95, 1.08, 0.86) + vec3(0.02, 0.03, 0.0), murk * 0.6);
	// the bed in the shallows
	float see = shallow * 0.55 * (1.0 - murk * 0.85);
	vec3 bc = mix(deep.rgb, bed.rgb, 0.5) * (0.75 + 0.4 * texture(n_soft, q * 2.2 + nw.xz * 0.2).r);
	col = mix(col, bc, see);
	// the sky mirrored at low angles
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	col = mix(col, sky.rgb, fres * 0.55);
	// streaks of foam riding the current
	float st = texture(n_fine, vec2(fq.x * 0.35, q.y * 3.0 + h0 * 0.4)).r;
	float streak = smoothstep(0.66 - rapids * 0.1, 0.8, st) * (0.12 + 0.4 * rapids);
	// foam lapping at the banks
	float wob = (texture(n_soft, vec2(q.x * 0.9, q.y * 0.3 + lt * 0.08)).r - 0.5) * 0.08 + sin(lt * 1.5 + q.x * 3.0) * 0.012;
	float bub = 0.6 + 0.6 * texture(n_fine, q * 3.0 + vec2(lt * 0.1, 0.0)).r;
	float lap = smoothstep(0.08 + wob, 0.02 + wob, sd);
	float ring = smoothstep(0.03, 0.0, abs(sd - 0.13 - wob * 1.4)) * 0.18 * bub;
	float f = clamp(streak + lap * bub + ring, 0.0, 1.0);
	col = mix(col, foam.rgb, f);
	ALBEDO = col;
	ROUGHNESS = mix(0.06, 0.6, f);
	SPECULAR = 0.6;
	METALLIC = 0.0;
}
