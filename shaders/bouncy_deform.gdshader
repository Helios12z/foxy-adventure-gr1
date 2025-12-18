shader_type canvas_item;

// Parameters for strong jelly bounce
uniform float bounce_amplitude : hint_range(0.0, 100.0) = 15.0; 
uniform float bounce_speed : hint_range(0.0, 20.0) = 5.0;      
uniform float squash_amount : hint_range(0.0, 1.0) = 0.4;  
uniform float sway_amount : hint_range(0.0, 0.5) = 0.0; // New: Rotation sway

// New parameter: Exact size of the rectangle to find center accurately
uniform vec2 rect_size;

// Pivot Y: 0.5 = Center (Default), 1.0 = Bottom (For characters standing on ground)
uniform float pivot_y : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	float time = TIME * bounce_speed;
	float sine = sin(time);
	
	// 1. Calculate Center/Pivot based on passed Rect Size and Pivot Y
	vec2 size_used = rect_size;
	
	// Fallback to texture size if rect_size is missing
	if (size_used.x <= 0.0) {
		size_used = 1.0 / TEXTURE_PIXEL_SIZE;
	}
	
	vec2 center = vec2(size_used.x * 0.5, size_used.y * pivot_y);
	
	// 2. Move VERTEX to origin (relative to pivot)
	vec2 pos = VERTEX - center;
	
	// 3. Calculate Factors
	float bounce_offset = -sine * bounce_amplitude; 
	
	// Squash factor
	float factor = sine * squash_amount;
	float scale_y = 1.0 + factor;
	float scale_x = 1.0 - factor;
	
	// Sway (Rotation) - Use a slower cosine wave for left-right sway
	float sway_angle = cos(time * 0.7) * sway_amount;
	
	// 4. Apply Scaling
	pos.x *= scale_x;
	pos.y *= scale_y;
	
	// 5. Apply Rotation (Sway)
	if (sway_amount > 0.001) {
		float cos_a = cos(sway_angle);
		float sin_a = sin(sway_angle);
		vec2 rotated;
		rotated.x = pos.x * cos_a - pos.y * sin_a;
		rotated.y = pos.x * sin_a + pos.y * cos_a;
		pos = rotated;
	}
	
	// 6. Restore Position + Apply Bounce Offset
	VERTEX = pos + center;
	VERTEX.y += bounce_offset;
}
