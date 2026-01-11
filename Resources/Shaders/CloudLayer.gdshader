shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);
uniform float cloud_scale = 0.5;
uniform float cloud_speed = 0.05;
uniform float cloud_threshold = 0.5; // Higher = fewer clouds
uniform float shadow_strength = 0.4;

// Simple noise function
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
	float frequency = 1.0;
	
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void fragment() {
	// Animate clouds
	vec2 uv = UV * cloud_scale;
	uv.x += TIME * cloud_speed;
	
	// Generate cloud pattern
	float cloud_pattern = fbm(uv);
	
	// Threshold to create distinct clouds
	float cloud_mask = smoothstep(cloud_threshold - 0.1, cloud_threshold + 0.1, cloud_pattern);
	
	// Mix cloud color with shadow
	vec4 final_color = mix(shadow_color, cloud_color, cloud_mask);
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a * shadow_strength;
}
