extends Node

@export var camera_bottom_limit_y: float = INF

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

func _ready() -> void:
	# Only handle portal/door spawning, NOT auto-respawn
	# Defeat screen will handle respawning now
	GameManager.respawn_at_portal()
