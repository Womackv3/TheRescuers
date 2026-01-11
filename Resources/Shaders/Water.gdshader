shader_type spatial;
// Water now responds to lighting

// Colors
uniform vec3 albedo : source_color = vec3(0.2, 0.4, 0.9); // Brightened
uniform vec3 foam_color : source_color = vec3(0.9, 0.95, 1.0); // White/Light Blue

// Animation
uniform float speed = 0.5;
uniform sampler2D noise_texture : filter_nearest; // Pixelated noise look

void fragment() {
	// Scrolling UVs for flow
	// Flow diagonally (down-left? or just linear)
	vec2 flow_uv = UV * 2.0 + vec2(0.0, TIME * speed); 
	
	// Sample noise
	float n = texture(noise_texture, flow_uv).r;
	
	// Second layer of noise moving faster for variance?
	float n2 = texture(noise_texture, UV * 3.0 + vec2(TIME * speed * 1.5, 0.0)).r;
	
	// Combine
	float combined = mix(n, n2, 0.5);
	
	// Threshold for "Riptides" (White Foam)
	// Hard step for pixel art style
	// Increased threshold to reduce noise (was 0.65)
	float foam = step(0.75, combined);
	
	// "Flow Lines" - streaks?
	// Maybe modulated by sin wave for strips
	float flow_line = step(0.8, sin(flow_uv.y * 20.0 + n * 5.0));
	
	// Final Mix
	float highlight = max(foam, flow_line * 0.3); // Foam is full opaque, lines are subtle?
	if (foam > 0.5) 
		ALBEDO = foam_color;
	else
		ALBEDO = albedo;
		
	ROUGHNESS = 0.1;
	SPECULAR = 0.5;
}
