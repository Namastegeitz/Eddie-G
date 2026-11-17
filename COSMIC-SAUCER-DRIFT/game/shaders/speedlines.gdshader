shader_type canvas_item;
// Speed lines streaming out from the centre toward the screen edges.
uniform float amount = 0.0;
uniform float aspect = 1.777;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }
void fragment() {
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float r = length(p) / (0.5 * aspect);
	float a = atan(p.y, p.x) / 6.2831853 + 0.5;
	float lanes = 110.0;
	float lane = floor(a * lanes);
	float rnd = hash(lane);
	float lf = abs(fract(a * lanes) - 0.5);
	float thin = 1.0 - smoothstep(0.04, 0.16, lf);
	float band = fract(r * 1.6 - TIME * (1.4 + rnd * 1.8) - rnd * 5.0);
	float streak = smoothstep(0.0, 0.08, band) * (1.0 - smoothstep(0.08, 0.5, band));
	float mask = smoothstep(0.3, 0.85, r);
	float on = step(0.45, rnd);
	COLOR = vec4(tint.rgb, tint.a * amount * mask * streak * thin * on * 0.75);
}
