extends Node2D

@export var lifetime: float = 1.5
@export var fade_time: float = 0.3

func _ready() -> void:
	var tw := create_tween()
	tw.set_parallel(false)
	var wait_time: float = max(0.0, lifetime - fade_time)
	if wait_time > 0.0:
		tw.tween_interval(wait_time)
	var sprite := get_node_or_null("Sprite2D")
	if sprite and fade_time > 0.0:
		tw.tween_property(sprite, "modulate:a", 0.0, fade_time)
	tw.tween_callback(Callable(self, "queue_free"))
