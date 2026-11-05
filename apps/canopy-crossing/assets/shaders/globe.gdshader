shader_type canvas_item;
// The world map's digital globe, drawn per pixel: each pixel inside the
// sphere is turned back into a latitude / longitude and looked up in
// assets/world/globe_map.png (R land, G coastline glow, B country borders).
// On top: LED dots on an even grid (bright on land, faint over the sea), a
// latitude / longitude grid, a scanning sweep, rim light and an atmosphere
// halo outside the sphere. The pins are drawn over this by the Globe widget,
// which uses the same projection.

uniform sampler2D map_tex : filter_linear_mipmap, repeat_enable;
uniform float lon0 = 0.0;          // longitude at the centre (radians)
uniform float tilt = 0.0;          // latitude at the centre (radians)
uniform float time = 0.0;
uniform vec2 rect_size = vec2(500.0, 500.0);
uniform float radius = 0.92;       // of half the rect's shorter side
uniform vec4 ocean_col : source_color = vec4(0.02, 0.09, 0.17, 1.0);
uniform vec4 land_col : source_color = vec4(0.3, 1.0, 0.55, 1.0);
uniform vec4 glow_col : source_color = vec4(0.35, 0.9, 1.0, 1.0);
uniform float dot_deg = 1.15;      // dot spacing in degrees of latitude
uniform float detail = 1.0;        // 0 = plain map, 1 = dots, grid, sweep


vec3 sample_map(vec2 uv_c) {
	vec2 uv = vec2(fract(uv_c.x), clamp(uv_c.y, 0.001, 0.999));
	return textureGrad(map_tex, uv, dFdx(uv_c), dFdy(uv_c)).rgb;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * rect_size;
	float R = min(rect_size.x, rect_size.y) * 0.5 * radius;
	vec2 q = p / R;
	float d = length(q);
	float px = 1.0 / R;
	// atmosphere halo just outside the sphere
	float halo = exp(-max(d - 1.0, 0.0) * 16.0) * 0.5 * smoothstep(1.0 - px, 1.0 + px * 2.0, d);
	vec4 outside = vec4(glow_col.rgb, halo);
	if (d >= 1.0 + px) {
		COLOR = outside;
	} else {
		float z = sqrt(max(0.0, 1.0 - d * d));
		vec3 v = vec3(q.x, -q.y, z);
		float ct = cos(tilt);
		float st = sin(tilt);
		vec3 w = vec3(v.x, v.y * ct + v.z * st, -v.y * st + v.z * ct);
		float la = asin(clamp(w.y, -1.0, 1.0));
		float lo = atan(w.x, w.z) + lon0;
		float latd = degrees(la);
		float lond = degrees(lo);
		vec2 uv_c = vec2(lo / (2.0 * PI) + 0.5, 0.5 - la / PI);
		vec3 m = sample_map(uv_c);

		// LED dots: rows of latitude, each row split evenly around the globe
		float row = floor(latd / dot_deg);
		float lat_c = (row + 0.5) * dot_deg;
		float n = max(1.0, floor(360.0 * cos(radians(lat_c)) / dot_deg));
		float cell = 360.0 / n;
		float lon_w = lond - 360.0 * floor((lond + 180.0) / 360.0);
		float col_i = floor((lon_w + 180.0) / cell);
		float lon_c = -180.0 + (col_i + 0.5) * cell;
		vec2 dd = vec2((latd - lat_c), (lon_w - lon_c) * cos(radians(latd)));
		float dist = length(dd);
		float aa = max(fwidth(latd), 0.0001) * 1.2;
		float dot_r = dot_deg * 0.34;
		float dot_m = 1.0 - smoothstep(dot_r - aa, dot_r + aa, dist);
		vec2 uv_dot = vec2((lon_c + 180.0) / 360.0, (90.0 - lat_c) / 180.0);
		float land_dot = textureLod(map_tex, uv_dot, 0.0).r;
		float twinkle = 0.8 + 0.2 * sin(time * 2.0 + hash(vec2(row, col_i)) * 40.0);

		// latitude / longitude grid every 15 degrees
		float gl = abs(fract(latd / 15.0 + 0.5) - 0.5) * 15.0;
		float gn = abs(fract(lond / 15.0 + 0.5) - 0.5) * 15.0;
		float grid = max(1.0 - smoothstep(0.0, fwidth(latd) * 1.2, gl), 1.0 - smoothstep(0.0, fwidth(lond) * 1.2, gn));
		float eq = 1.0 - smoothstep(0.0, fwidth(latd) * 1.6, abs(latd));

		// a scan line sweeping round the globe
		float sweep_lon = mod(time * 24.0, 360.0) - 180.0;
		float ds = mod(lon_w - sweep_lon + 540.0, 360.0) - 180.0;
		float sweep = ds < 0.0 ? exp(ds / 10.0) : exp(-ds / 1.2);

		vec3 col = ocean_col.rgb * (0.55 + 0.45 * z);
		col = mix(col, land_col.rgb * 0.16 + ocean_col.rgb * 0.5, m.r * 0.85);
		col += glow_col.rgb * dot_m * (1.0 - land_dot) * 0.07 * detail;
		col += land_col.rgb * dot_m * land_dot * twinkle * mix(0.0, 0.85, detail);
		col += land_col.rgb * m.r * 0.22 * (1.0 - detail);
		col += glow_col.rgb * m.g * 0.85;
		col += land_col.rgb * m.b * 0.28;
		col += glow_col.rgb * (grid * 0.1 + eq * 0.12) * detail;
		col += glow_col.rgb * sweep * (0.06 + 0.4 * m.r) * detail;
		// light from the upper left, and a cyan rim at the edge
		vec3 L = normalize(vec3(-0.45, 0.55, 0.75));
		col *= 0.55 + 0.6 * max(dot(v, L), 0.0);
		col += glow_col.rgb * pow(1.0 - z, 3.0) * 0.55;
		col += vec3(1.0) * pow(max(dot(reflect(-L, v), vec3(0.0, 0.0, 1.0)), 0.0), 40.0) * 0.12;
		float edge = 1.0 - smoothstep(1.0 - px * 1.5, 1.0 + px * 0.5, d);
		COLOR = mix(outside, vec4(col, 1.0), edge);
	}
}
