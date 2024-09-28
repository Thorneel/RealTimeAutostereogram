shader_type spatial;

render_mode unshaded;

struct ModifiedColor {
	bool is_modified;
	vec3 color;
};

uniform float eye_distance_in_pixels = 160.; // also separation for furthest object
uniform float min_distance_in_pixels = 250.; // between closest object and screen
uniform float pixel_per_meter = 4331.; // on the screen
uniform float eye_screen_distance_in_pixels = 3000.;
uniform float min_culling = 0.;
uniform float max_culling = -1.; // ignored if negative
uniform float depth_scale = 1.;

uniform bool wall_eyed = true;

uniform bool from_center_to_borders = true;

uniform sampler2D noise_img;
uniform bool use_greyscale = true;
uniform vec2 noise_displ_green = vec2(73., 377.); // TODO currently unused
uniform vec2 noise_displ_blue = vec2(183., 271.); // TODO currently unused
uniform sampler2D pattern_img;
uniform bool use_noise = true;

uniform bool round_colors = false;

uniform bool show_screen = false;

uniform bool show_reticle = true;
uniform sampler2D reticle_img;
uniform float reticle_opacity = 0.2; // between 0 and 1

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

const float very_large_positive_number = 1e20;


// ********** VERTEX **********

void vertex() {
 	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


// *********** FRAGMENT **********

float getLinearDepth(vec2 coord, mat4 inv_projection_matrix){
	float depth = textureLod(depth_texture, coord, 0.0).r;
	vec3 ndc = vec3(coord * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}


float getPixelSeparationFromLinearDepth(float linear_depth){
	linear_depth = max(linear_depth, min_culling);
	if (max_culling > 0.) {
		linear_depth = min(linear_depth, max_culling);
	}
	
	float linear_depth_in_pixels = linear_depth * pixel_per_meter * depth_scale;
	
	float separation_in_pixels = eye_distance_in_pixels * (
		min_distance_in_pixels + linear_depth_in_pixels
	) / (
		eye_screen_distance_in_pixels + min_distance_in_pixels + linear_depth_in_pixels
	);
	
	return separation_in_pixels;
}


/*
Gives the horizontal pixel separation required by this linear depth
from the backgroudn texture to achieve autostereogram effect
*/
float getPixelSeparation(vec2 coord, mat4 inv_projection_matrix) {
	float linear_depth = getLinearDepth(coord, inv_projection_matrix);
	return getPixelSeparationFromLinearDepth(linear_depth);
}


float getOffsetFromCentralPixel(mat4 inv_projection_matrix){
	float pixel_separation = getPixelSeparation(vec2(0.5), inv_projection_matrix);
	return pixel_separation / 2.;
}


vec2 getNoisePixelCoordCenterToBorders(vec2 uv_coord, vec2 viewport_size, mat4 inv_projection_matrix){
	
	vec2 pix_coord = uv_coord * viewport_size;
	float pixel_repeat = (eye_distance_in_pixels * depth_scale * 2.) + 1.;
	
	vec2 current_pixel = pix_coord;
	
	float screen_midpoint = viewport_size.x * 0.5;
	bool left_of_center = current_pixel.x < screen_midpoint;
	float offset_sign = left_of_center ? -1. : 1.;
	
	float side_offset = getPixelSeparationFromLinearDepth(very_large_positive_number) * 0.5;
	current_pixel.x -= side_offset * offset_sign;
	
	// arbitrarily large number, see if a number can be calculated instead?
	int max_iterations = 128;
	for (int i = 0; i < max_iterations; i++) {
		
		float pixel_separation = getPixelSeparation(current_pixel / viewport_size, 
				inv_projection_matrix);
		
		float offset = pixel_repeat * offset_sign;
		
		if (wall_eyed) {
			offset = pixel_separation * offset_sign;
		} else {
			offset -= pixel_separation * offset_sign;
		}
		
		float offset_midpoint = current_pixel.x - (offset * 0.5);
		
		// Equivalent of a boolean xor as ^^ is not supported yet
		if (left_of_center != (offset_midpoint < screen_midpoint - (side_offset * offset_sign))) {
			break;
		}
		current_pixel.x -= offset;
		
	}
	
	current_pixel.x += side_offset * offset_sign;
	
	// For centering the pattern image used
	current_pixel.x = mod(current_pixel.x, pixel_repeat) - (viewport_size.x * 0.5 - pixel_repeat);
	
	return current_pixel;
}


vec2 getNoisePixelCoordLeftToRight(vec2 pix_coord, vec2 viewport_size, mat4 inv_projection_matrix){
	
	float pixel_repeat = (eye_distance_in_pixels * depth_scale * 2.) + 1.;
	
	float left_offset = getOffsetFromCentralPixel(inv_projection_matrix);
	
	vec2 current_pixel = pix_coord;
	current_pixel.x -= left_offset;
	
	// arbitrarily large number, see if a number can be calculated instead?
	int max_iterations = 128;
	
	for (int i = 0; i < max_iterations; i++) {
		
		if (current_pixel.x < 0.) {
			break;
		}
		
		float pixel_separation = getPixelSeparation(current_pixel / viewport_size, 
				inv_projection_matrix);
		
		float offset = pixel_repeat;
		
		if (wall_eyed) {
			offset = pixel_separation;
		} else {
			offset -= pixel_separation;
		}
		current_pixel.x -= offset;
		
	}
	
	current_pixel.x = mod(current_pixel.x, pixel_repeat);
	
	return current_pixel;
}


vec2 getNoisePixelCoord(vec2 uv_coord, vec2 viewport_size, mat4 inv_projection_matrix){
	if (from_center_to_borders) {
		return getNoisePixelCoordCenterToBorders(uv_coord, viewport_size, inv_projection_matrix);
	} else {
		vec2 pix_coord = uv_coord * viewport_size;
		return getNoisePixelCoordLeftToRight(pix_coord, viewport_size, inv_projection_matrix);
	}
}


vec3 addColorInFrontOfColor(vec3 background_color, vec4 front_color){
	vec3 result_color = (
			background_color * (1. - front_color.a)
		) + (front_color.rgb * front_color.a);
	return result_color;
}


vec3 addSingleReticle(vec3 initial_color, vec2 uv_coord, float x_offset, vec2 viewport_size,
		mat4 inv_projection_matrix){
	
	vec2 reticle_res = vec2(textureSize(reticle_img, 0));
	vec2 half_reticle_res = reticle_res * 0.5;
	vec2 offset_from_center_coord = (uv_coord - 0.5) * viewport_size;
	
	// if we are above or under reticle height, 
	// the reticle cannot be there and we return the initial color instead
	if ((abs(offset_from_center_coord.y) > half_reticle_res.y)){
//		return vec3(1.0);
		return initial_color;
	}
	
	vec3 color_result = initial_color;
	
	
	if (abs(offset_from_center_coord.x + x_offset) < half_reticle_res.x){
		vec2 reticle_coord = offset_from_center_coord + vec2(x_offset, 0.) - half_reticle_res;
		vec2 reticle_uv = reticle_coord / reticle_res;
		vec4 reticle_color = textureLod(reticle_img, reticle_uv, 0.0);
		color_result = addColorInFrontOfColor(initial_color, reticle_color);
	}
	
	return color_result;
}


vec3 addReticles(vec3 initial_color, vec2 uv_coord, vec2 viewport_size, 
		mat4 inv_projection_matrix) {
	
	vec2 pix_coord = uv_coord * viewport_size;
	float left_offset = getOffsetFromCentralPixel(inv_projection_matrix);
	
	vec3 color_result = initial_color;
	// Right reticle
	color_result = addSingleReticle(color_result, uv_coord, left_offset, viewport_size, inv_projection_matrix);
	// Left reticle
	color_result = addSingleReticle(color_result, uv_coord, -left_offset, viewport_size, inv_projection_matrix);
	
	return color_result;
}


vec3 getNoiseColor(vec2 noise_pix_coord){
	vec2 noise_res = vec2(textureSize(noise_img, 0));
	vec2 noise_coord = noise_pix_coord / noise_res;
	vec3 noise_color = textureLod(noise_img, noise_coord, 0.0).rgb;
	noise_color = smoothstep(0.2, 0.8, noise_color);
	return noise_color;
}


vec3 getColoredNoiseColor(vec2 noise_pix_coord){
	vec3 result_color = getNoiseColor(noise_pix_coord);
	result_color.g = getNoiseColor(noise_pix_coord + noise_displ_green).g;
	result_color.b = getNoiseColor(noise_pix_coord + noise_displ_blue).b;
	return result_color;
}


void fragment() {
	
	vec2 noise_pix_coord = getNoisePixelCoord(SCREEN_UV, VIEWPORT_SIZE, 
			INV_PROJECTION_MATRIX);
	
	vec3 noise_color;
	if (use_noise) {
		if (use_greyscale) {
			noise_color = getNoiseColor(noise_pix_coord);
		} else {
			noise_color = getColoredNoiseColor(noise_pix_coord);
		}
	} else {
		vec2 noise_res = vec2(textureSize(pattern_img, 0));
		vec2 noise_coord = noise_pix_coord / noise_res;
		noise_color = textureLod(pattern_img, noise_coord, 0.0).rgb;
	}
	
	if (round_colors) {
		noise_color = round(noise_color);
	}
	
	vec3 color_result = noise_color;
	
	if (show_screen) {
		vec3 screen = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
		color_result = ((color_result * 0.9) + (screen * 0.1));
	}
	
	if (show_reticle){
		color_result = addReticles(color_result, SCREEN_UV, VIEWPORT_SIZE, 
				INV_PROJECTION_MATRIX);
	}
	
	ALBEDO = color_result;
	
	// FOR TESTING
	
	float pixel_separation = getPixelSeparation(SCREEN_UV, INV_PROJECTION_MATRIX);
//	ALBEDO = vec3(linear_depth / 255.);
//	ALBEDO = vec3((pixel_separation - 50.) / 512.);
	
//	ALBEDO = textureLod(screen_texture, noise_pix_coord / VIEWPORT_SIZE, 0.0).rgb;
	
//	ALBEDO = (color_result * 2. + clamp(vec3(linear_depth / 8000.), 0., 1.)) / 3.;
	
//	ALBEDO = getNoiseColor(SCREEN_UV * VIEWPORT_SIZE, noise_img_1);
	
}
