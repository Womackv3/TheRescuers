shader_type spatial;
// Water surface now responds to lighting

uniform vec3 albedo : source_color = vec3(0.4, 0.6, 0.9); // Light Blue
uniform sampler2D noise_texture : filter_nearest;

void fragment() {
	// Very subtle movement
	// Slow scroll
	vec2 uv = UV * 3.0 + vec2(TIME * 0.1, TIME * 0.05);
	
	float n = texture(noise_texture, uv).r;
	
	// Create faint ripple lines
	// Use sine of noise to create bands
	float ripple = sin(n * 20.0 + TIME * 2.0);
	
	// Mix base color with slightly lighter color for ripple
	vec3 movement = mix(albedo, albedo + vec3(0.1, 0.1, 0.1), step(0.9, ripple));
	
	ALBEDO = movement;
	ALPHA = 0.4;
	ROUGHNESS = 0.2;
	SPECULAR = 0.5;
}
