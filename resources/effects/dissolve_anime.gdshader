shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color = vec4(1.0, 0.92, 0.5, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.9;
uniform float outline_thickness : hint_range(0.5, 2.5) = 1.0;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    // Random per-pixel dissolve based on UV; speed controlled via 'progress'
    float noise = rand(UV * vec2(123.45, 456.78));
    float show = step(noise, progress); // 1 when noise <= progress

    // Mask original color by dissolve visibility
    float alpha_masked = base.a * show;

    // Bright anime-style outline around dissolving edge
    vec2 px = TEXTURE_PIXEL_SIZE * outline_thickness;
    float neigh = 0.0;
    neigh = max(neigh, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
    neigh = max(neigh, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
    neigh = max(neigh, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
    neigh = max(neigh, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);

    // Outline appears where not yet shown but neighbor has content
    float outline_mask = (1.0 - show) * step(0.001, neigh);
    vec4 outline_col = vec4(glow_color.rgb, glow_color.a * glow_strength * (1.0 - progress)) * outline_mask;

    COLOR = vec4(base.rgb, alpha_masked) + outline_col;
}