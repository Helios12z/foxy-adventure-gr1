extends Node

@export var camera_bottom_limit_y: float = INF

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

func _ready() -> void:
	GameManager.is_scene_boss = false
	GameManager.is_scene_boss = false
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
