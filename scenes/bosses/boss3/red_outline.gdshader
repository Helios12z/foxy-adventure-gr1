shader_type canvas_item;

// Outline properties
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Red color
uniform float outline_width : hint_range(0.0, 10.0) = 2.0; // Thickness of outline
uniform bool show_outline = true; // Toggle outline on/off

// Flash properties
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 final_color = tex;

	if (show_outline) {
		// Sample neighboring pixels to detect edges
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float outline = 0.0;

		// Sample 8 directions around the pixel
		outline += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
		outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;

		// Normalize the outline detection
		outline = min(outline, 1.0);

		// If current pixel is transparent but neighbors are not, draw outline
		if (tex.a < 0.1 && outline > 0.0) {
			final_color = outline_color;
		}
	}

	// Apply flash
	vec3 rgb = mix(final_color.rgb, flash_color.rgb, flash_amount);
	COLOR = vec4(rgb, final_color.a);
}
