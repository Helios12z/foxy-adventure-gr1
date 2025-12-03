extends StaticBody2D

@export var x_amplitude: float = 30.0
@export var x_frequency: float = 0.2
@export var y_amplitude: float = 6.0
@export var y_frequency: float = 0.5
@export var bob_accel: float = 60.0
@export var bob_damping: float = 3.0

@export var deform_strength: float = 0.08
@export var deform_in_time: float = 0.2
@export var deform_out_time: float = 0.3

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: HitArea2D = $HitArea2D if has_node("HitArea2D") else null

var _base_pos: Vector2
var _t: float = 0.0

var _cur_x: float = 0.0
var _vel_x: float = 0.0

var _cur_y: float = 0.0
var _vel_y: float = 0.0

var _base_scale: Vector2
var _deform_tw: Tween

func _ready() -> void:
    _base_pos = position
    _base_scale = sprite.scale
    set_process(true)
    if hit_area != null:
        hit_area.hitted.connect(_on_hitted)

func _process(delta: float) -> void:
    _t += delta

    var target_x := sin(_t * TAU * x_frequency) * x_amplitude
    var err_x := target_x - _cur_x
    _vel_x += err_x * bob_accel * delta
    _vel_x *= max(0.0, 1.0 - bob_damping * delta)
    _cur_x += _vel_x * delta

    var target_y := sin(_t * TAU * y_frequency) * y_amplitude
    var err_y := target_y - _cur_y
    _vel_y += err_y * bob_accel * delta
    _vel_y *= max(0.0, 1.0 - bob_damping * delta)
    _cur_y += _vel_y * delta

    position = _base_pos + Vector2(_cur_x, _cur_y)

func _on_hitted(_area: Area2D) -> void:
    _play_deform()

func _play_deform() -> void:
    if _deform_tw != null and _deform_tw.is_running():
        _deform_tw.kill()
    var target_scale := Vector2(
        _base_scale.x * (1.0 + deform_strength),
        _base_scale.y * (1.0 - deform_strength)
    )
    _deform_tw = create_tween()
    _deform_tw.tween_property(sprite, "scale", target_scale, deform_in_time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    _deform_tw.tween_property(sprite, "scale", _base_scale, deform_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
