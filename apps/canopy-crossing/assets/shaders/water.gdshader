shader_type canvas_item;
// River / swamp surface for the bird's-eye view: depth shading from the far
// bank, two drifting ripple layers, caustic glints and foam at the banks.
// `lt` is the lane's own clock (follows slow-motion and pause), `flow` its
// current in tiles per second, `tile` the tile size in pixels.

uniform vec4 base : source_color = vec4(0.18, 0.55, 0.62, 1.0);
uniform vec4 deep : source_color = vec4(0.08, 0.32, 0.4, 1.0);
uniform vec4 foam : source_color = vec4(0.85, 0.95, 0.95, 1.0);
uniform float flow = 0.4;
uniform float lt = 0.0;
uniform float tile = 80.0;
uniform float glints = 1.0;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec2 p = lp / tile;
	float x = p.x - lt * flow;
	float d = smoothstep(-0.5, 0.45, p.y);
	vec3 col = mix(deep.rgb, base.rgb, 0.25 + 0.75 * d);
	float w1 = sin(x * 5.4 + p.y * 8.0 + lt * 1.3);
	float w2 = sin(x * 9.7 - p.y * 12.0 - lt * 2.1 + 1.7);
	col += vec3(0.045) * (w1 * 0.6 + w2 * 0.4);
	float g = sin(x * 11.0 + sin(p.y * 17.0 + lt * 0.9) * 1.6) * sin(p.y * 21.0 - lt * 1.7 + x * 3.1);
	col = mix(col, foam.rgb, smoothstep(0.86, 0.99, g) * 0.32 * glints);
	float bank = smoothstep(0.36, 0.5, abs(p.y));
	col = mix(col, p.y < 0.0 ? deep.rgb * 0.8 : foam.rgb, bank * (p.y < 0.0 ? 0.55 : 0.22));
	COLOR = vec4(col, 1.0);
}
