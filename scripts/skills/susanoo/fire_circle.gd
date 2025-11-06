extends Node2D

signal appeared
signal disappeared

@export var appear_duration: float = 0.6
@export var disappear_duration: float = 0.5
@export var scale_factor: float = 8.0

var _sprite: Sprite2D
var _base_scale: Vector2

func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D")
	if _sprite:
		_base_scale = _sprite.scale
		var c := _sprite.modulate
		c.a = 0.0
		_sprite.modulate = c

func appear() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "modulate:a", 1.0, appear_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "scale", _base_scale * scale_factor, appear_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	appeared.emit()

func disappear() -> void:
	if _sprite == null:
		queue_free()
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "modulate:a", 0.0, disappear_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_sprite, "scale", _base_scale, disappear_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	disappeared.emit()
	queue_free()
