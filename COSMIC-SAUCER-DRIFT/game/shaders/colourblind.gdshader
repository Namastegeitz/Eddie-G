shader_type canvas_item;
// Colour-blind assist ("daltonize"): simulate how the screen looks with one
// kind of colour blindness, then move the lost difference into colours that
// can still be told apart. mode: 1 protanopia, 2 deuteranopia, 3 tritanopia.
// Matrices: Fidaner, Lin & Ozguven, "Analysis of Color Blindness" (2005).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform int mode = 2;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float L = 17.8824 * c.r + 43.5161 * c.g + 4.11935 * c.b;
	float M = 3.45565 * c.r + 27.1554 * c.g + 3.86714 * c.b;
	float S = 0.0299566 * c.r + 0.184309 * c.g + 1.46709 * c.b;
	float l = L;
	float m = M;
	float s = S;
	if (mode == 1) {
		l = 2.02344 * M - 2.52581 * S;
	} else if (mode == 2) {
		m = 0.494207 * L + 1.24827 * S;
	} else if (mode == 3) {
		s = -0.395913 * L + 0.801109 * M;
	}
	vec3 sim = vec3(
		0.0809444479 * l - 0.130504409 * m + 0.116721066 * s,
		-0.0102485335 * l + 0.0540193266 * m - 0.113614708 * s,
		-0.000365296938 * l - 0.00412161469 * m + 0.693511405 * s);
	vec3 err = c - sim;
	vec3 shift = vec3(0.0, 0.7 * err.r + err.g, 0.7 * err.r + err.b);
	COLOR = vec4(clamp(c + shift, 0.0, 1.0), 1.0);
}
