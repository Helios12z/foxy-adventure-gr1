shader_type canvas_item;

uniform float deform_y : hint_range(-1.0, 1.0) = 0.0; // Negative = Squash, Positive = Stretch
uniform float pivot_offset_y : hint_range(0.0, 1.0) = 0.5; // 0.5 means pivot is at bottom of centered sprite (h/2)

void vertex() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// Define pivot relative to sprite center (0,0)
	// If sprite is centered, bottom is at +size.y/2.
	// We use pivot_offset_y to control this. 0.0 = center, 0.5 = bottom.
	vec2 pivot = vec2(0.0, size.y * pivot_offset_y);
	
	vec2 pos = VERTEX - pivot;
	
	// Volume preserving scale
	float scale_y = 1.0 + deform_y;
	float scale_x = 1.0;
	if (scale_y > 0.001) {
		scale_x = 1.0 / scale_y;
	}
	
	pos.x *= scale_x;
	pos.y *= scale_y;
	
	VERTEX = pos + pivot;
}
