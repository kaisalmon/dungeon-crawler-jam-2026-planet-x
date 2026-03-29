// NOTE: Shader automatically converted from Godot Engine 4.5.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.001);
uniform ivec2 albedo_texture_size;
// Note: Point size is usually ignored outside of point rendering modes, but keeping it as per original.
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// --- Sprite Sheet Settings ---
uniform int TOTAL_FRAMES = 8;
uniform bool invert_rotation = false; // If true, rotates frames in the opposite direction.

// Varying to pass the calculated UV shift from vertex to fragment.
// Using 'flat' interpolation is critical to prevent artifacts at the wrap-around point (frame 7 -> 0).
varying flat vec2 frame_uv_offset;

void vertex() {
	// 1. Calculate needed frame based on camera angle relative to object's local Z.

	// Transform camera position from World Space into the object's Local Space.
	// In local space, the object's forward direction is always fixed along the Z axis.
	vec3 local_cam_pos = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;

	// Calculate the angle on the XZ plane using atan2 (atan(y,x) analogy).
	// atan(x, z) usually gives 0 looking down +Z, PI/2 down +X, etc.
	float angle_rad = atan(local_cam_pos.x, local_cam_pos.z);
	if (invert_rotation) {
		angle_rad = -angle_rad;
	}

	// Normalize angle to [0.0, 1.0) range over a full circle.
	float angle_norm = angle_rad / TAU;

	// Calculate the index.
	// We multiply by total frames.
	// We add 0.5 before modulo so that frame 0 is centered on the forward direction,
	// rather than starting exactly at the forward direction.
	float frame_index = floor(mod(angle_norm * float(TOTAL_FRAMES) + 0.5, float(TOTAL_FRAMES)));

	// Assuming a horizontal sprite sheet strip.
	float frame_width = 1.0 / float(TOTAL_FRAMES);
	// Calculate the UV shift required for this frame.
	// ASSUMPTION: The mesh's original UVs are already scaled to fit one frame width (e.g., 0.0 to 0.125).
	frame_uv_offset = vec2(frame_index * frame_width, 0.0);


	// 2. Standard Billboard setup

	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Billboard Mode: Y-Billboard
	// This constructs a rotation matrix that faces the camera but only rotates around Y.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	// Apply the offset calculated in the vertex shader to select the correct sprite frame.
	vec2 base_uv = UV + frame_uv_offset;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	ALPHA *= albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}