shader_type spatial;

uniform vec3 albedo : source_color;
uniform sampler2D noise_texture;
uniform int pattern_type = 0; // 0=None, 1=Brick, 2=Wood, 3=Cobble

varying vec3 world_pos;
varying vec3 local_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = VERTEX;
}

void fragment() {
	vec3 col = albedo;
	
	// Noise Detail
	float noise = texture(noise_texture, world_pos.xz * 0.5).r;
	
	if (pattern_type == 1) { // Brick (Walls)
		// Grid pattern based on world position
		// Assuming 1.0 block size
		float w = 0.05; // Grout width
		
		// Offset every other row
		float y_idx = floor(world_pos.y * 2.0); // 2 rows per block
		float x_offset = mod(y_idx, 2.0) * 0.5;
		
		// Check X/Z depending on normal? 
		// Simple triplanar-ish approach or just box projection logic
		// Just using world coords directly for patterns
		
		float bx = fract(world_pos.x + x_offset);
		float by = fract(world_pos.y * 2.0);
		float bz = fract(world_pos.z + x_offset);
		
		// Determine which face we are roughly looking at or just apply 3D grid
		// Simple logic: Darken edges
		if (bx < w || bx > 1.0-w || by < w || by > 1.0-w || bz < w || bz > 1.0-w) {
			col *= 0.6; // Grout color
		}
		
		// Add noise texture
		col *= 0.9 + noise * 0.2;
		
	} else if (pattern_type == 2) { // Wood (Planks)
		// Horizontal lines
		float line = fract(world_pos.y * 4.0); // 4 planks per block
		if (line < 0.1 || line > 0.9) {
			col *= 0.5; // Gap
		}
		
		// Wood grain noise (stretched)
		float grain = texture(noise_texture, vec2(world_pos.x * 0.5, world_pos.y * 4.0)).r;
		col *= 0.8 + grain * 0.4;
		
	} else if (pattern_type == 3) { // Cobblestone/Stone
		// Voronoi-ish or just heavy noise
		// Simple: Heavy contrast noise
		float stone = texture(noise_texture, world_pos.xz).r;
		float stone2 = texture(noise_texture, world_pos.yz).r;
		
		float val = (stone + stone2) * 0.5;
		if (val < 0.3) col *= 0.7; // Dark spots
		else if (val > 0.7) col *= 1.2; // Highlights
		
		col *= 0.9 + noise * 0.2;
	} else {
		// Default noise
		col *= 0.95 + noise * 0.1;
	}
	
	ALBEDO = col;
	ROUGHNESS = 0.8;
}
