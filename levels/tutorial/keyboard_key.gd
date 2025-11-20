extends Node2D

@export var key_text: String = ""
@export var normal_texture: Texture2D
@export var pressed_texture: Texture2D
@export var action_name: String = ""
@export var custom_size: Vector2 = Vector2.ZERO
@export var custom_scale: Vector2 = Vector2(-1, -1)

var _sprite: Sprite2D
var _label: Label

func _ready() -> void:
    _sprite = $Sprite2D
    _label = $Label
    _apply_key_text()
    _apply_size()
    _update_texture(false)

func _process(_dt: float) -> void:
    if action_name != "" and InputMap.has_action(action_name):
        var is_pressed := Input.is_action_pressed(action_name)
        _update_texture(is_pressed)

func _apply_key_text() -> void:
    if _label and key_text != "":
        _label.text = key_text
        _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        # giữ nguyên vị trí nếu người dùng đã set trong scene

func _apply_size() -> void:
    if _sprite and _sprite.texture:
        if custom_size.x > 0.0 and custom_size.y > 0.0:
            var tex_size: Vector2 = _sprite.texture.get_size()
            if tex_size.x > 0 and tex_size.y > 0:
                _sprite.scale = Vector2(custom_size.x / tex_size.x, custom_size.y / tex_size.y)
        # Cho phép chỉnh trực tiếp scale X/Y qua export
        if custom_scale.x > 0.0 and custom_scale.y > 0.0:
            _sprite.scale = custom_scale

func _update_texture(pressed: bool) -> void:
    if not _sprite:
        return
    if pressed and pressed_texture != null:
        _sprite.texture = pressed_texture
    elif normal_texture != null:
        _sprite.texture = normal_texture
    # re-apply size if texture changed
    _apply_size()