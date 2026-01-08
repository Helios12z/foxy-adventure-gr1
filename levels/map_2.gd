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
	# Only handle portal/door spawning, NOT auto-respawn
	# Defeat screen will handle respawning now
	# Handle portal/door spawning first
	if not GameManager.respawn_at_portal():
		print("[Map2] No portal target, attempting checkpoint respawn...")
		GameManager.respawn_at_checkpoint()

	# Ensure all AudioStreamPlayers in the scene loop (Fix for Web/itch.io)
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
			# Check if it has a stream
			if child.stream:
				# Force connection to ensure loop
				if not child.finished.is_connected(child.play):
					child.finished.connect(child.play)
				# Ensure it's playing if it was set to autoplay but stopped or failed
				if child.autoplay and not child.playing:
					child.play()
