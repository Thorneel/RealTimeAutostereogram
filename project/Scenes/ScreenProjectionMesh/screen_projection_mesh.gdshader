shader_type spatial;

render_mode unshaded;

uniform float eye_half_distance_in_pixels = 120;
uniform float min_distance_in_pixels = 130;
uniform float pixel_per_meter = 4331;
uniform float eye_screen_distance_in_pixels = 3000;
uniform float min_culling = 0;
uniform float max_culling = -1; // ignored if negative

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

/*
Gives the horizontal pixel half-separation required by this linear depth
from the backgroudn texture to achieve autostereogram effect
*/
float getPixelHalfSeparation(float linear_depth) {
	linear_depth = max(linear_depth, min_culling);
	if (max_culling > 0.) {
		linear_depth = min(linear_depth, max_culling);
	}
	
	float linear_depth_in_pixels = linear_depth * pixel_per_meter;
	// TODO pre-calculate that value directly in the uniform
	
	// TODO replace with a uniform value calculated once beforehand
//	float min_distance_in_pixels = 
//		(view_distance * min_half_separation_in_pixels) 
//		/ (eye_half_distance_in_pixels - min_half_separation_in_pixels);
	
	float half_separation_in_pixels = eye_half_distance_in_pixels * (
		min_distance_in_pixels + linear_depth_in_pixels
	) / (
		eye_screen_distance_in_pixels + min_distance_in_pixels + linear_depth_in_pixels
	);
	
	return half_separation_in_pixels;
}

/*
Store a float value in a Vec2 for storage as color.

Big-Endian: x contains the large part, y contains the small part and decimals
Two bits are for below decimal point, the rest for above.
The binary representation of the number will be: xxxxxxxx yyyyyy.yy when being
used in a color (8 bits per color value, translated from the 0-1 interval)
If the value is greater than can be stored in a Vec2, then it is set at max value.
However as this is to store a horizontal pixel separation, this should never happen.

(If monitor pixel density inceases enoguh for this to be an issue in the future, this 
part will have to be changed.)
*/
vec2 floatToVec2(float value) {
//	value = 80.;
	
	float xVal = floor(value/64.);
	float yVal = mod(value, 64);
	
	vec2 result = vec2(xVal, yVal)/256.;
	
	return result;
}


void vertex() {
 	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	float half_separation = getPixelHalfSeparation(linear_depth);
	vec2 stored_separation = floatToVec2(half_separation);
	
	// Contains the half-separation value for this pixel as 0-1 range to use as color
	// Note: can only store value up to 255. If the eye separation (in pixels) is
	// greater than 511, this will not work and will in effect cull far distances
	float hs_color = half_separation/256.;

	vec3 screen = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;

//	NORMAL_MAP = vec3(depth);
//	NORMAL_MAP.r = depth;
//	ALBEDO = COLOR.xyz;
//	NORMAL_MAP = screen;
	ALBEDO = screen;
	ALBEDO = view.xyz;
	ALBEDO = vec3(view.w);
//	ALBEDO = vec3(linear_depth/100.);
//	ALBEDO.xy = stored_separation;
	ALBEDO.xyz = vec3(hs_color);
}