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
	# Ensure music loops
	music_player.finished.connect(music_player.play)

func lock_camera_limit(limit_x: int) -> void:
	if GameManager.player and GameManager.player.has_node("Camera2D"):
		var cam = GameManager.player.get_node("Camera2D")
		cam.limit_right = limit_x
		print("[Map3] Locked camera limit to: ", limit_x)

func unlock_camera_limit() -> void:
	if GameManager.player and GameManager.player.has_node("Camera2D"):
		var cam = GameManager.player.get_node("Camera2D")
		var current = cam.limit_right
		
		# If already unlocked, ignore
		if current >= 10000000: return
		
		# Enable limit smoothing for internal engine smoothness
		if "limit_smoothed" in cam:
			cam.limit_smoothed = true
		
		var tw = create_tween()
		# Use CUBIC + EASE_IN_OUT for maximum smoothness (start slow, end slow)
		# 3.0 seconds duration provides a cinematic "opening" feel
		tw.tween_property(cam, "limit_right", current + 4000, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func(): cam.limit_right = 10000000)
		
		print("[Map3] Unlocking camera limit smoothly (CUBIC/IN_OUT) from ", current)
