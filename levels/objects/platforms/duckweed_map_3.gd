extends StaticBody2D

@export var bob_amplitude: float = 2.0
@export var bob_frequency: float = 0.6
@export var bob_accel: float = 60.0
@export var bob_damping: float = 3.0

@export var deform_strength: float = 0.06
@export var deform_in_time: float = 0.2
@export var deform_out_time: float = 0.3

@onready var sprite: Sprite2D = $Sprite2D
@onready var detect_area: Area2D = $DetectArea if has_node("DetectArea") else null

var _base_y: float
var _t: float = 0.0
var _cur_y: float = 0.0
var _vel_y: float = 0.0

var _base_scale: Vector2
var _deform_tw: Tween

func _ready() -> void:
	_base_y = position.y
	_base_scale = sprite.scale
	set_process(true)
	if detect_area != null:
		detect_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	var target := sin(_t * TAU * bob_frequency) * bob_amplitude
	var err := target - _cur_y
	_vel_y += err * bob_accel * delta
	_vel_y *= max(0.0, 1.0 - bob_damping * delta)
	_cur_y += _vel_y * delta
	position.y = _base_y + _cur_y

func _on_body_entered(_body: Node) -> void:
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
