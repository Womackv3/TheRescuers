shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float texture_resolution = 64.0; // Lower = more pixelated
uniform float vertex_snap = 0.1; // Vertex snapping for PS1 jitter effect

varying vec3 world_pos;

void vertex() {
	// PS1-style vertex snapping
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Snap vertices to grid
	world_pos = floor(world_pos / vertex_snap) * vertex_snap;
	
	// Apply snapped position
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	// Quantize UV coordinates for pixelated texture effect
	vec2 quantized_uv = floor(UV * texture_resolution) / texture_resolution;
	
	// Sample texture with quantized UVs
	vec4 tex_color = texture(albedo_texture, quantized_uv);
	
	ALBEDO = tex_color.rgb * albedo_color.rgb;
	ALPHA = tex_color.a * albedo_color.a;
}
