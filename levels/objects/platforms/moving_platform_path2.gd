extends Path2D

@onready var path_follow: PathFollow2D = $PathFollow2D
var _is_moving: bool = false
@export var move_duration: float = 2.0

func _on_interactive_area_2d_interacted() -> void:
	if _is_moving:
		return
	_is_moving = true
	var target := 1.0 if path_follow.progress_ratio < 0.5 else 0.0
	var tween := create_tween()
	tween.tween_property(path_follow, "progress_ratio", target, move_duration)
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	_is_moving = false
