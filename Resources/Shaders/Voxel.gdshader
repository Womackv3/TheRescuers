shader_type spatial;

uniform vec3 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform int pattern_type = 0; // 0=subtle, 1=wood_grain, 2=cracked

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 final_color = albedo;
	
	if (pattern_type == 1) {
		// WOOD GRAIN - Horizontal lines with noise
		float grain_noise = texture(texture_albedo, vec2(world_pos.x * 0.5, world_pos.y * 2.0)).r;
		float grain_lines = fract(world_pos.y * 4.0); // 4 planks per block
		
		// Create wood grain effect
		float grain = grain_noise * 0.3;
		if (grain_lines < 0.05 || grain_lines > 0.95) {
			grain -= 0.2; // Darker gaps between planks
		}
		
		final_color = albedo * (0.85 + grain);
		
	} else if (pattern_type == 2) {
		// CRACKED/ROCKY - More subtle, less vertical lines
		// Use multiple noise samples at different scales
		float noise1 = texture(texture_albedo, world_pos.xz * 0.5).r;
		float noise2 = texture(texture_albedo, world_pos.xz * 0.7 + vec2(0.3, 0.3)).r;
		float noise3 = texture(texture_albedo, world_pos.xz * 1.0 + vec2(0.7, 0.1)).r;
		
		// Blend multiple noise layers for more natural variation
		float combined = (noise1 + noise2 + noise3) / 3.0;
		
		// Much more subtle variation (±8% instead of ±30%)
		final_color = albedo * (0.92 + combined * 0.16);
		
	} else {
		// SUBTLE VARIATION (grass, etc)
		float noise = texture(texture_albedo, world_pos.xz * 0.3).r;
		final_color = albedo * (0.975 + noise * 0.05);
	}
	
	ALBEDO = final_color;
	ROUGHNESS = roughness;
	SPECULAR = 0.3;
}
