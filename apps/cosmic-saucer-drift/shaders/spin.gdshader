shader_type spatial;
// Spins and bobs MultiMesh instances on the GPU (pods, crates) so the CPU
// only touches their transforms when they're collected or respawn.
// Facet shading + a bright fresnel edge give them a gem/glass look;
// frame > 0 draws glowing edges on box faces (item crates).
render_mode unshaded, cull_back;
uniform vec4 color : source_color = vec4(0.25, 1.0, 0.95, 1.0);
uniform float energy = 2.2;
uniform float spin = 2.0;
uniform float tumble = 0.0;
uniform float bob = 0.25;
uniform float alpha = 1.0;
uniform float frame = 0.0;

mat3 rot_y(float a) { return mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a))); }
mat3 rot_x(float a) { return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cos(a), sin(a)), vec3(0.0, -sin(a), cos(a))); }

varying vec3 lnorm;

void vertex() {
	float ph = float(INSTANCE_ID) * 1.7;
	mat3 r = rot_y(TIME * spin + ph) * rot_x(TIME * tumble + ph);
	VERTEX = r * VERTEX + vec3(0.0, sin(TIME * 3.0 + ph) * bob, 0.0);
	NORMAL = r * NORMAL;
	lnorm = NORMAL;
}

void fragment() {
	float facet = 0.55 + 0.45 * clamp(normalize(lnorm).y * 0.5 + 0.5 + normalize(lnorm).x * 0.25, 0.0, 1.0);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 c = color.rgb * energy * facet + color.rgb * rim * 1.4 + vec3(rim * 0.4);
	if (frame > 0.0) {
		vec2 f = fract(UV * vec2(3.0, 2.0));
		float e = max(max(1.0 - smoothstep(0.0, 0.1, f.x), smoothstep(0.9, 1.0, f.x)), max(1.0 - smoothstep(0.0, 0.1, f.y), smoothstep(0.9, 1.0, f.y)));
		c = mix(color.rgb * 0.35 + rim * color.rgb, color.rgb * energy * 1.8 + 0.2, e);
	}
	ALBEDO = c;
	ALPHA = color.a * alpha;
}
