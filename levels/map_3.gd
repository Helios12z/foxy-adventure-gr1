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
	# Handle portal/door spawning first
	if not GameManager.respawn_at_portal():
		# If no portal target, try to respawn at checkpoint
		print("[Map3] No portal target, attempting checkpoint respawn...")
		GameManager.respawn_at_checkpoint()

	# Add background music like Water Prietest level
	var music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://asset/sounds/water_prietess_sound/level_ambient.mp3")
	music_player.volume_db = 6.0
	music_player.bus = "SFX"
	add_child(music_player)
	music_player.play()
