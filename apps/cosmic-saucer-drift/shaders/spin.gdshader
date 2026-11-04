shader_type spatial;
// Spins and bobs MultiMesh instances on the GPU (pods, crates) so the CPU
// only touches their transforms when they're collected or respawn.
render_mode unshaded, cull_back;
uniform vec4 color : source_color = vec4(0.25, 1.0, 0.95, 1.0);
uniform float energy = 2.2;
uniform float spin = 2.0;
uniform float tumble = 0.0;
uniform float bob = 0.25;
uniform float alpha = 1.0;

mat3 rot_y(float a) { return mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a))); }
mat3 rot_x(float a) { return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cos(a), sin(a)), vec3(0.0, -sin(a), cos(a))); }

void vertex() {
	float ph = float(INSTANCE_ID) * 1.7;
	mat3 r = rot_y(TIME * spin + ph) * rot_x(TIME * tumble + ph);
	VERTEX = r * VERTEX + vec3(0.0, sin(TIME * 3.0 + ph) * bob, 0.0);
	NORMAL = r * NORMAL;
}

void fragment() {
	ALBEDO = color.rgb * energy;
	ALPHA = color.a * alpha;
}
