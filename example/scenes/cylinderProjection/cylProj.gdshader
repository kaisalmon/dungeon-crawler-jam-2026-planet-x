shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_nearest, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest, repeat_enable;
uniform sampler2D texture_emission : hint_default_black, filter_nearest, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform bool no_shading = false;


uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
global uniform float planet_radius;
global uniform vec3 curve_origin;
global uniform bool use_camera_as_curve_origin;  // false = curve_origin, true = CAMERA_POSITION_WORLD


void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;

    // Get world position of this vertex
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Choose curve origin based on flag
    vec3 origin = use_camera_as_curve_origin ? CAMERA_POSITION_WORLD : curve_origin;

    float dist_x = world_pos.x - origin.x;
    float dist_z = world_pos.z - origin.z;
    float dist_sq = dist_x * dist_x + dist_z * dist_z;

    // Apply curvature: push vertices down based on distance²
    float drop = dist_sq / (2.0 * planet_radius);

    // Apply curve in WORLD SPACE by modifying world_pos directly
    vec3 curved_world_pos = world_pos;
    curved_world_pos.y -= drop;

    // Transform curved world position back to local space for VERTEX output
    VERTEX = (inverse(MODEL_MATRIX) * vec4(curved_world_pos, 1.0)).xyz;

    // Calculate curved surface normal
    vec3 curve_normal_world = normalize(vec3(
        dist_x / planet_radius,
        1.0,
        dist_z / planet_radius
    ));

    // Transform original normal to world space
    vec3 world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);

    // Rotate original normal by the curvature rotation
    vec3 world_up = vec3(0.0, 1.0, 0.0);
    vec3 rotation_axis = cross(world_up, curve_normal_world);
    float sin_angle = length(rotation_axis);

    vec3 rotated_normal;
    if (sin_angle > 0.0001) {
        rotation_axis /= sin_angle;
        float cos_angle = curve_normal_world.y;

        rotated_normal = world_normal * cos_angle
                       + cross(rotation_axis, world_normal) * sin_angle
                       + rotation_axis * dot(rotation_axis, world_normal) * (1.0 - cos_angle);
    } else {
        rotated_normal = world_normal;
    }

    // Transform back to local space
    NORMAL = normalize(mat3(transpose(inverse(MODEL_MATRIX))) * rotated_normal);
}

void fragment() {
    vec2 base_uv = UV;

    vec4 albedo_tex = texture(texture_albedo, base_uv);
    ALBEDO = albedo.rgb * albedo_tex.rgb;
    ALPHA = albedo.a * albedo_tex.a;
    ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;

    float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
    METALLIC = metallic_tex * metallic;
    SPECULAR = specular;

    vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
    float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
    ROUGHNESS = roughness_tex * roughness;

    if (no_shading) {
        EMISSION = ALBEDO;
        ALBEDO = vec3(0.0);
    }else{
        EMISSION = texture(texture_emission, base_uv).rgb * albedo.rgb;
        if (length(EMISSION) > 0.0) {
            EMISSION *= 2.0; // Boost emission for visibility
        }
    }
}
