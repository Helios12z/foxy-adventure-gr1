shader_type canvas_item;

// Biến dạng cho dash chéo lên (Godot 4 CanvasItem)
uniform float warp : hint_range(0.0, 3.0) = 1.4;
uniform float squash : hint_range(0.0, 1.0) = 0.6;
uniform float lean : hint_range(0.0, 1.0) = 0.5;
uniform float diag_strength : hint_range(0.0, 2.0) = 0.8;
uniform float dir_x = 1.0;   // hướng ngang: 1 hoặc -1
uniform float dir_y = -1.0;  // hướng dọc: -1 để chéo lên

void vertex() {
    // Dùng UV.y để chuẩn hoá theo chiều dọc (0..1)
    float norm_y = UV.y;

    // Nghiêng theo hướng chéo (giảm dần từ dưới lên trên)
    vec2 diag = vec2(dir_x, dir_y) * diag_strength;
    VERTEX += (diag * (1.0 - norm_y));

    // Squash theo trục Y để tạo cảm giác nén
    VERTEX.y *= (1.0 - squash);

    // Warp theo X dựa trên Y (kéo căng theo hướng di chuyển)
    VERTEX.x += warp * dir_x * (norm_y - 0.5);

    // Lean nhẹ theo trục X
    VERTEX.x += lean * dir_x * 0.5;
}

void fragment() {
    COLOR = texture(TEXTURE, UV);
}