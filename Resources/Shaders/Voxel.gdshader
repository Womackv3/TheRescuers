shader_type spatial;

uniform vec3 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform int pattern_type = 0; // 0=subtle, 1=wood_grain, 2=cracked

// Cloud shadow parameters
uniform float cloud_scale = 0.15;
uniform float cloud_speed = 0.05;
uniform float cloud_threshold = 0.5;
uniform float shadow_strength = 0.3;

varying vec3 world_pos;

// Simple noise for clouds
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	
	for (int i = 0; i < 3; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 final_color = albedo;
	
	if (pattern_type == 1) {
		// WOOD GRAIN
		float grain_noise = texture(texture_albedo, vec2(world_pos.x * 0.5, world_pos.y * 2.0)).r;
		float grain_lines = fract(world_pos.y * 4.0);
		
		float grain = grain_noise * 0.3;
		if (grain_lines < 0.05 || grain_lines > 0.95) {
			grain -= 0.2;
		}
		
		final_color = albedo * (0.85 + grain);
		
	} else if (pattern_type == 2) {
		// CRACKED/ROCKY
		float noise1 = texture(texture_albedo, world_pos.xz * 0.5).r;
		float noise2 = texture(texture_albedo, world_pos.xz * 0.7 + vec2(0.3, 0.3)).r;
		float noise3 = texture(texture_albedo, world_pos.xz * 1.0 + vec2(0.7, 0.1)).r;
		
		float combined = (noise1 + noise2 + noise3) / 3.0;
		final_color = albedo * (0.92 + combined * 0.16);
		
	} else {
		// SUBTLE VARIATION
		float noise_val = texture(texture_albedo, world_pos.xz * 0.3).r;
		final_color = albedo * (0.975 + noise_val * 0.05);
	}
	
	// Add cloud shadows
	vec2 cloud_uv = world_pos.xz * cloud_scale;
	cloud_uv.x += TIME * cloud_speed;
	
	float cloud_pattern = fbm(cloud_uv);
	float cloud_shadow = smoothstep(cloud_threshold - 0.1, cloud_threshold + 0.1, cloud_pattern);
	
	// Darken areas under clouds
	final_color *= mix(1.0 - shadow_strength, 1.0, cloud_shadow);
	
	ALBEDO = final_color;
	ROUGHNESS = roughness;
	SPECULAR = 0.3;
}
