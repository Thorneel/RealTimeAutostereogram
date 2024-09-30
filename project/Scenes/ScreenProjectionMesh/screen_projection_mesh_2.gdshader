shader_type spatial;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	// Place fragment code here.
	
	vec3 screen = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float c_min = screen.x;
	float c_max = screen.x;
	for (int i = 1; i <= 8; i++) {
		vec2 displacement = vec2(float(i), 0.);
		vec3 c_left = textureLod(screen_texture, SCREEN_UV + displacement, 0.0).rgb;
		vec3 c_right = textureLod(screen_texture, SCREEN_UV - displacement, 0.0).rgb;
		c_min = min(c_min, min(c_left.x, c_right.x));
		c_max = max(c_max, max(c_left.x, c_right.x));
	}
	ALBEDO.x = screen.x;
	ALBEDO.y = c_min;
	ALBEDO.z = c_max;
	ALBEDO = vec3(0.1, 0.5, 0.8);
	ALPHA = 1.0;
	
}
