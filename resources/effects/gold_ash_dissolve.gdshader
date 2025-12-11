shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.2, 1.0); // Gold/Yellow
uniform float particle_size : hint_range(0.0, 100.0) = 40.0;
uniform float particle_speed : hint_range(0.0, 10.0) = 2.0;
uniform float spread : hint_range(0.0, 5.0) = 1.0;

// Random function
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Noise function
float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip), rand(ip+vec2(1.0,0.0)), u.x),
        mix(rand(ip+vec2(0.0,1.0)), rand(ip+vec2(1.0,1.0)), u.x), u.y);
    return res;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float n = noise(UV * particle_size);
    
    // Calculate dissolve threshold
    // Reverse progress: 0.0 = full visible, 1.0 = fully dissolved
    // We want it to start normal, then glow, then dissolve into ash
    
// Effect phases:
    // 0.0 - 0.2: Turn Solid Gold
    // 0.2 - 1.0: Main body turns to dust
    
    vec4 final_color = tex;
    
    // 1. Turn to Gold (Sustain)
    // Mix original color with gold based on early progress, then STAY gold
    float gold_mix = smoothstep(0.0, 0.15, progress);
    vec3 solid_gold = glow_color.rgb; // purely use the uniform color
    
    // Apply gold tint/replacement
    // We want it to look like the object IS gold now
    final_color.rgb = mix(final_color.rgb, solid_gold, gold_mix);
    
    // 2. Dissolve Pattern
    float dissolve_prog = smoothstep(0.15, 1.0, progress);
    
    // Noisy dust edge
    float edge_width = 0.15;
    float dust_mask = smoothstep(dissolve_prog - edge_width, dissolve_prog, n);
    float solid_mask = step(dissolve_prog, n);
    
    if (solid_mask < 0.5) {
        // Disintegrating part (Dust)
        // Make the dust particles fade out cleanly
        // 'dust_mask' provides a gradient at the edge of the noise
        float drift = (dissolve_prog - n) / edge_width; // 0.0 at edge, 1.0 far out
        
        // Particles fade alpha as they drift 'away' (in noise space)
        final_color.a = tex.a * (1.0 - drift); 
        
        // Ensure dust is gold
        final_color.rgb = solid_gold;
    } else {
        // Remaining solid part is fully gold (already set above)
        final_color.a = tex.a;
    }
    
    COLOR = final_color;
}
