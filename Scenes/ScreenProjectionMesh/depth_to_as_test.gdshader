shader_type spatial;

render_mode unshaded;

struct ModifiedColor {
	bool is_modified;
	vec3 color;
};

uniform float eye_half_distance_in_pixels = 116.; // also separation for furthest object
uniform float min_distance_in_pixels = 250.; // between closest object and screen
uniform float pixel_per_meter = 4331.; // on the screen
uniform float eye_screen_distance_in_pixels = 3000.;
uniform float min_culling = 0.;
uniform float max_culling = -1.; // ignored if negative
uniform float depth_scale = 1.;

uniform bool wall_eyed = true;

uniform sampler2D noise_img_1;
uniform sampler2D noise_img_2;
uniform float noise_img_1_proportion = 1.; // between 0 and 1
uniform bool use_greyscale = true; // TODO currently unused
uniform vec2 noise_displ_green = vec2(73., 377.); // TODO currently unused
uniform vec2 noise_displ_blue = vec2(183., 271.); // TODO currently unused
uniform sampler2D pattern_img;
uniform bool use_noise = false;

uniform bool round_colors = false;

uniform bool show_screen = false;

uniform sampler2D reticle_img;
uniform float reticle_opacity = 0.2; // between 0 and 1

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;


// ********** VERTEX **********

void vertex() {
 	POSITION = vec4(VERTEX, 1.0);
}


// *********** FRAGMENT **********

float getLinearDepth(vec2 coord, mat4 inv_projection_matrix){
	float depth = textureLod(depth_texture, coord, 0.0).r;
	vec3 ndc = vec3(coord * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}


/*
Gives the horizontal pixel half-separation required by this linear depth
from the backgroudn texture to achieve autostereogram effect
*/
float getPixelSeparation(float linear_depth) {
	linear_depth = max(linear_depth, min_culling);
	if (max_culling > 0.) {
		linear_depth = min(linear_depth, max_culling);
	}
	
	float linear_depth_in_pixels = linear_depth * pixel_per_meter * depth_scale;
	
	float half_separation_in_pixels = eye_half_distance_in_pixels * (
		min_distance_in_pixels + linear_depth_in_pixels
	) / (
		eye_screen_distance_in_pixels + min_distance_in_pixels + linear_depth_in_pixels
	);
	
	float pixel_separation = half_separation_in_pixels * 2.;
	return pixel_separation;
}


float getCentralPixelSeparation(mat4 inv_projection_matrix){
	float center_linear_depth = getLinearDepth(vec2(0.5), inv_projection_matrix);
	float center_pixel_separation = getPixelSeparation(center_linear_depth);
	return center_pixel_separation/2.;
}


vec2 getNoisePixelCoord(vec2 uv_coord, vec2 viewport_size, mat4 inv_projection_matrix){
	
	float pixel_repeat = (eye_half_distance_in_pixels * depth_scale * 2.) + 1.;
	
	vec2 pix_coord = uv_coord * viewport_size;
	float x_offset = getCentralPixelSeparation(inv_projection_matrix);
	
	vec2 current_pixel = pix_coord;
	current_pixel.x -= x_offset;
	
	// arbitrarily large number, see if a number can be calculated instead?
	int max_iterations = 128;
	
	for (int i = 0; i < max_iterations; i++) {
		
		if (current_pixel.x < 0.) {
			break;
		}
		
		float linear_depth = getLinearDepth(current_pixel / viewport_size, 
				inv_projection_matrix);
		float pixel_separation = getPixelSeparation(linear_depth);
		
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


vec3 add_color_in_front_of_color(vec3 background_color, vec4 front_color){
	vec3 result_color = (
			background_color * (1. - front_color.a)
		) + (front_color.rgb * front_color.a);
	return result_color;
}


ModifiedColor addReticleIfNeeded(vec3 initial_color, vec2 uv_coord, vec2 offset_from_center_coord,
		mat4 inv_projection_matrix){
	
	vec2 reticle_res = vec2(textureSize(reticle_img, 0));
	vec2 half_reticle_res = reticle_res * 0.5;
	
	
	float linear_depth = getLinearDepth(uv_coord, inv_projection_matrix);
	float half_pixel_separation = getPixelSeparation(linear_depth) * 0.5;
	if (
		(offset_from_center_coord.x + half_reticle_res.x > half_pixel_separation)
		&& (offset_from_center_coord.x - half_reticle_res.x < half_pixel_separation)
	){
		vec2 reticle_coord = 
				offset_from_center_coord 
				- half_reticle_res 
				- vec2(half_pixel_separation, 0.);
		vec2 reticle_uv = reticle_coord / reticle_res;
		vec4 reticle_color = textureLod(reticle_img, reticle_uv, 0.0);
		vec3 color_result = add_color_in_front_of_color(initial_color, reticle_color);
		
		
		return ModifiedColor(true, color_result);
	}
	
	return ModifiedColor(false, initial_color);
}


vec3 addReticleToColor(vec3 initial_color, vec2 uv_coord, vec2 viewport_size, 
		mat4 inv_projection_matrix){
	
	vec2 pix_coord = uv_coord * viewport_size;
	vec2 reticle_res = vec2(textureSize(reticle_img, 0));
	vec2 half_reticle_res = reticle_res * 0.5;
	
	vec2 offset_from_center_coord = (uv_coord - 0.5) * viewport_size;
	float half_max_pixel_separation = eye_half_distance_in_pixels;
	
	// if we are above or under reticle height, 
	// or if we are beyond max distance from center, 
	// the reticle cannot be there and we return the initial color instead
	if (
		(abs(offset_from_center_coord.y) > half_reticle_res.y)
		|| (abs(offset_from_center_coord.x) - half_reticle_res.x > half_max_pixel_separation)
	){
//		return vec3(1.0);
		return initial_color;
	}
	
	
	// RIGHT RETICLE
	
	ModifiedColor right_reticle_color = addReticleIfNeeded(initial_color, uv_coord, 
			offset_from_center_coord, inv_projection_matrix);
	if (right_reticle_color.is_modified) {
		return right_reticle_color.color;
	}
	
	if (offset_from_center_coord.x > 0.) {
		return initial_color;
	}
	
	
	// LEFT RETICLE
	
	float offset_uv_x = -offset_from_center_coord.x / viewport_size.x;
	vec2 mirror_uv = uv_coord + vec2(offset_uv_x, 0.);
	vec2 mirror_offset = offset_from_center_coord * vec2(-1., 1.);
	float mirror_linear_depth = getLinearDepth(uv_coord, inv_projection_matrix);
	float mirror_half_pixel_separation = getPixelSeparation(mirror_linear_depth) * 0.5;
	ModifiedColor left_reticle_color = addReticleIfNeeded(initial_color, mirror_uv, 
			mirror_offset, inv_projection_matrix);
	if (left_reticle_color.is_modified) {
		return left_reticle_color.color;
	}
	
	return initial_color;
}


vec3 getNoiseColor(vec2 noise_pix_coord, sampler2D noise_img){
	vec2 noise_res = vec2(textureSize(noise_img, 0));
	vec2 noise_coord = noise_pix_coord / noise_res;
	vec3 noise_color = textureLod(noise_img, noise_coord, 0.0).rgb;
	noise_color = smoothstep(0.2, 0.8, noise_color);
	return noise_color;
}


vec3 getColoredNoiseColor(vec2 noise_pix_coord, sampler2D noise_img){
	vec3 result_color = getNoiseColor(noise_pix_coord, noise_img);
	result_color.g = getNoiseColor(noise_pix_coord + noise_displ_green, noise_img).g;
	result_color.b = getNoiseColor(noise_pix_coord + noise_displ_blue, noise_img).b;
	return result_color;
}


void fragment() {
	
	vec2 noise_pix_coord = getNoisePixelCoord(SCREEN_UV, VIEWPORT_SIZE, 
			INV_PROJECTION_MATRIX);
	
	vec3 noise_color;
	if (use_noise) {
		vec3 noise_color_1;
		vec3 noise_color_2;
		if (use_greyscale){
			noise_color_1 = getNoiseColor(noise_pix_coord, noise_img_1);
			noise_color_2 = getNoiseColor(noise_pix_coord, noise_img_2);
		} else {
			noise_color_1 = getColoredNoiseColor(noise_pix_coord, noise_img_1);
			noise_color_2 = getColoredNoiseColor(noise_pix_coord, noise_img_2);
		}
		float proportion = clamp(noise_img_1_proportion, 0., 1.);
		noise_color = noise_color_1 * proportion + noise_color_2 * (1. - proportion);
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
	
	color_result = addReticleToColor(color_result, SCREEN_UV, VIEWPORT_SIZE, 
			INV_PROJECTION_MATRIX);
	
	ALBEDO = color_result;
	
	// FOR TESTING
	
	float linear_depth = getLinearDepth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float pixel_separation = getPixelSeparation(linear_depth);
//	ALBEDO = vec3(linear_depth / 255.);
//	ALBEDO = vec3((pixel_separation - 50.) / 512.);
	
//	ALBEDO = textureLod(screen_texture, noise_pix_coord / VIEWPORT_SIZE, 0.0).rgb;
	
//	ALBEDO = (color_result * 2. + clamp(vec3(linear_depth / 8000.), 0., 1.)) / 3.;
	
}
