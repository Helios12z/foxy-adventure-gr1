shader_type canvas_item;

// Golden glow shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform bool is_pulsing = false;
uniform float pulse_speed : hint_range(0.1, 5.0) = 2.0;
uniform float outline_width : hint_range(0.0, 100.0) = 5.0; // Acts as Glow Radius

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	// Pulse Logic
	float pulse = 1.0;
	if (is_pulsing) {
		pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
	}
	
	// SOFT GLOW ALGORITHM (Accumulated Sampling)
	// We verify surrounding pixels in multiple rings to create a gradient falloff
	float alpha_sum = 0.0;
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width; // Total Radius
	
	// Ring 1: Close (Sharpest)
	alpha_sum += texture(TEXTURE, UV + vec2(0, -size.y * 0.3)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(0, size.y * 0.3)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(-size.x * 0.3, 0)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(size.x * 0.3, 0)).a;
	
	// Ring 2: Medium (Softer)
	alpha_sum += texture(TEXTURE, UV + vec2(-size.x * 0.6, -size.y * 0.6)).a * 0.8;
	alpha_sum += texture(TEXTURE, UV + vec2(size.x * 0.6, size.y * 0.6)).a * 0.8;
	alpha_sum += texture(TEXTURE, UV + vec2(-size.x * 0.6, size.y * 0.6)).a * 0.8;
	alpha_sum += texture(TEXTURE, UV + vec2(size.x * 0.6, -size.y * 0.6)).a * 0.8;
	
	// Ring 3: Far (Faintest)
	alpha_sum += texture(TEXTURE, UV + vec2(0, -size.y)).a * 0.5;
	alpha_sum += texture(TEXTURE, UV + vec2(0, size.y)).a * 0.5;
	alpha_sum += texture(TEXTURE, UV + vec2(-size.x, 0)).a * 0.5;
	alpha_sum += texture(TEXTURE, UV + vec2(size.x, 0)).a * 0.5;
	
	// Normalize based on samples (Total max weight approx 9.2)
	// If current pixel is transparent, we use the glow
	float final_glow_alpha = (alpha_sum / 6.0); // Divider tunes density
	
	// Color: Bright Holy Gold (1.0, 0.95, 0.4)
	vec3 glow_color = vec3(1.0, 0.95, 0.4);
	
	if (col.a < 0.1 && final_glow_alpha > 0.01) {
		// Bloom Softness logic
		float final_alpha = clamp(final_glow_alpha * glow_intensity * pulse, 0.0, 1.0);
		
		// Optional: Add a white core near the object for that "shining" look
		vec3 final_color = mix(glow_color, vec3(1.0, 1.0, 0.8), final_glow_alpha * 0.5);
		
		COLOR = vec4(final_color, final_alpha);
	} else {
		COLOR = col;
	}
}
