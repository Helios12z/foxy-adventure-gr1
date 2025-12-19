extends Node

@export var camera_bottom_limit_y: float = INF

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

func _ready() -> void:
	# Handle portal/door spawning first
	if not GameManager.respawn_at_portal():
		# If no portal target, try to respawn at checkpoint
		print("[Stage] No portal target, attempting checkpoint respawn...")
		GameManager.respawn_at_checkpoint()
