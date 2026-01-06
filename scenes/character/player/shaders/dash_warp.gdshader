shader_type canvas_item;

// Amount of warp/curvature (0.0 = off, 1.0 = strong)
uniform float warp : hint_range(0.0, 1.0) = 0.0;
// Direction the player faces (-1.0 or 1.0)
uniform float dir = 1.0;
// Squash/stretch factor (0.0 = none, 1.0 = strong)
uniform float squash : hint_range(0.0, 1.0) = 0.0;
// Forward-lean factor for RUN (0.0 = off, 1.0 = strong)
uniform float lean : hint_range(0.0, 1.0) = 0.0;
// Cutoff along UV.y; only pixels above this are leaned (upper body)
uniform float lean_cutoff : hint_range(0.0, 1.0) = 0.58;
// Tint color for effects like QuickSand (default white = no tint)
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
    // Basic squash and stretch to imply speed
    float sx = 1.0 + 0.35 * squash;
    float sy = 1.0 - 0.25 * squash;
    VERTEX.x *= sx;
    VERTEX.y *= sy;

    // Directional curvature: bend along Y to create forward warp
    float y = UV.y;
    float curve = sin(y * 3.14159265) * warp; // peak in middle
    // Push forward relative to local sprite; world flip handled by node scale
    VERTEX.x += curve * 8.0;

    // Slight skew toward facing direction for motion feel
    float skew = (0.5 - y) * warp * 6.0;
    VERTEX.x += skew;

    // Forward-lean upper body only (keep legs grounded)
    if (lean > 0.001 && y <= lean_cutoff) {
        // Strength increases toward the top
        float amt = (lean_cutoff - y) / max(lean_cutoff, 0.0001);
        // Push upper body forward and slightly down
        // Push upper body forward in local space (node flip will mirror for left)
        VERTEX.x += amt * lean * 8.0;
        VERTEX.y += -amt * lean * 2.0;
    }
}

void fragment() {
    // Strictly preserve original texture RGB; only adjust alpha on dash
    vec4 base = texture(TEXTURE, UV);
    float out_a = base.a;

    if (warp > 0.001) {
        // Subtle fade on the trailing edge (opposite of dir)
        float edge = clamp((dir > 0.0 ? UV.x : 1.0 - UV.x), 0.0, 1.0);
        float fade = mix(0.85, 1.0, edge);
        out_a *= fade;
    }

    // Apply tint color (default white = no change)
    vec3 tinted_rgb = base.rgb * tint_color.rgb;
    
    // Respect CanvasItem modulate alpha (blink/invulnerability) without darkening RGB
    float mod_a = COLOR.a; // incoming CanvasItem COLOR contains modulate
    COLOR = vec4(tinted_rgb, out_a * mod_a * tint_color.a);
}
