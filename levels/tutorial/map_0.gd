extends Node

@export var camera_bottom_limit_y: float = INF
@export var show_comic_on_start: bool = true
@export var comic_pages_paths: Array[String] = []
var _comic_shown: bool = false
var _hover_music_playing: bool = false

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

# Challenge variables
var _challenge_active: bool = false
var _challenge_time: float = 60.0
# The arrow uses 60:00 format, so it's technically seconds:centiseconds 
# but usually it's mm:ss. User said "60:00" for 60s, so it's likely ss:ms or just 60 seconds.
# User said "đếm ngược 60s (cái này hiện theo kiểu 60:00 nha)". Usually means 60 seconds : 00 milliseconds
var _challenge_completed: bool = false
var _flash_timer: float = 0.0

func _ready() -> void:
	
	# Connect to HoverArea2D
	if has_node("HoverArea2D"):
		var hover_area = get_node("HoverArea2D")
		hover_area.body_entered.connect(_on_hover_area_entered)
		
	# Connect to EndHoverArea2D
	if has_node("EndHoverArea2D"):
		var end_hover_area = get_node("EndHoverArea2D")
		end_hover_area.body_entered.connect(_on_end_hover_area_entered)
		
	# Connect to ClockStart
	if has_node("ClockStart"):
		print("DEBUG: ClockStart found")
		var clock = get_node("ClockStart")
		if clock.has_signal("sword_given"):
			clock.sword_given.connect(_start_challenge_sequence)
			print("DEBUG: Clock signal connected")

	# Check if comic has already been shown for this map
	var already_shown = GameManager.is_comic_shown()
	
	if get_node_or_null("UI/ChallengeUI"):
		get_node("UI/ChallengeUI").visible = false
		
	if not already_shown:
		# If user wants comic on start, we play it.
		if show_comic_on_start and comic_pages_paths.size() > 0:
			# Play the comic
			_show_map_story()
		else:
			# If user disabled comic on start, just play ambient music
			_set_ambient_music_playing(true)
	else:
		# If already shown, just play ambient music
		_set_ambient_music_playing(true)

	# Only handle portal/door spawning, NOT auto-respawn
	# Defeat screen will handle respawning now
	if not GameManager.respawn_at_portal():
		# If no portal target, try to respawn at checkpoint
		print("[Map0] No portal target, attempting checkpoint respawn...")
		GameManager.respawn_at_checkpoint()
	
	if has_node("FoxyReachCutScene"):
		if GameManager.has_met_water_fairy:
			$FoxyReachCutScene.visible = false
			$FoxyReachCutScene/CollisionShape2D.disabled = true
			if has_node("WaterFairy"):
				$WaterFairy.queue_free()

	# Set Camera Limit
	_set_camera_limit(3350)

func _process(delta: float) -> void:
	if _challenge_active and not _challenge_completed:
		_challenge_time -= delta
		if _challenge_time < 0:
			_challenge_time = 0
			_fail_challenge()
		
		_update_challenge_ui(delta)

func _update_challenge_ui(delta: float) -> void:
	var ui = get_node_or_null("UI/ChallengeUI")
	if not ui: return
	
	var timer_lbl = ui.get_node_or_null("TimerLabel")
	var arrow = ui.get_node_or_null("Arrow")
	
	if timer_lbl:
		# Format 60:00 (Seconds:Milliseconds)
		var seconds = int(_challenge_time)
		var milliseconds = int(fmod(_challenge_time, 1.0) * 100) # Corrected to get centiseconds
		timer_lbl.text = "%02d:%02d" % [seconds, milliseconds]
		
		# Flash red when close to end (< 10s)
		if _challenge_time < 10.0:
			var mod = sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
			timer_lbl.modulate = Color(1, 1 - mod, 1 - mod)
		else:
			timer_lbl.modulate = Color.WHITE

	if arrow:
		# Smooth flash arrow
		_flash_timer += delta * 8.0 # Speed of flashing
		# Alpha oscillates smoothly between 0.2 and 1.0 using Sine wave
		arrow.modulate.a = 0.2 + 0.8 * (0.5 * (1.0 + sin(_flash_timer)))
		arrow.visible = true

func _show_map_story() -> void:
	var viewer_scene: PackedScene = load("res://scenes/ui/comic_viewer.tscn")
	var viewer := viewer_scene.instantiate()
	# nạp các trang theo đường dẫn cấu hình
	if "pages" in viewer:
		var arr: Array[Texture2D] = []
		for p in comic_pages_paths:
			var tex := load(p)
			if tex:
				arr.append(tex)
		viewer.pages = arr
	
	# Configure auto-play for Map 0
	var music = load("res://asset/sounds/start_game_music.ogg")
	var timestamps = [7.0, 14.0, 20.0, 29.0, 33.5, 37.0, 46.0]
	viewer.setup_auto_play(music, timestamps)
	
	viewer.finished.connect(_on_comic_finished)

	add_child(viewer)
	_comic_shown = true

func _on_comic_finished() -> void:
	_set_ambient_music_playing(true)
	# Mark comic as shown so it won't appear again on subsequent visits
	GameManager.mark_comic_shown()

func _set_ambient_music_playing(playing: bool) -> void:
	var music_nodes = ["Music2", "Music3"]
	for node_name in music_nodes:
		if has_node(node_name):
			var player = get_node(node_name)
			if player is AudioStreamPlayer:
				if playing:
					if not player.playing:
						player.play()
				else:
					player.stop()

func _on_hover_area_entered(body: Node2D) -> void:
	# Check if it's the player entering
	if body.name == "Player":
		# Unlock Hover Skill and Save
		GameManager.collect_hover_skill()
		
		# Music logic moved to challenge start

func _play_hover_music() -> void:
	if _hover_music_playing: return
	_hover_music_playing = true
	
	# Stop all ambient music
	_set_ambient_music_playing(false)
	
	# Play hover tutorial music
	var hover_music = load("res://asset/sounds/hover_tutorial_music.ogg")
	if hover_music:
		# Check if we have a dedicated hover music player, if not create one
		var music_player: AudioStreamPlayer
		if has_node("HoverMusic"):
			music_player = get_node("HoverMusic")
		else:
			music_player = AudioStreamPlayer.new()
			music_player.name = "HoverMusic"
			music_player.bus = "Music"
			music_player.stream = hover_music
			add_child(music_player)
			# Connect finished signal to loop from 1 second
			music_player.finished.connect(_on_hover_music_finished)
		
		if not music_player.playing:
			# Skip first 1 second
			music_player.play(1.0)

func _on_hover_music_finished() -> void:
	# Loop back to 1 second position (skip first 1 second)
	if has_node("HoverMusic"):
		var music_player = get_node("HoverMusic")
		music_player.play(1.0)

func _on_end_hover_area_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Stop challenge if active
		if _challenge_active:
			_challenge_active = false
			_challenge_completed = true
			var ui = get_node_or_null("UI/ChallengeUI")
			if ui: ui.visible = false
			
			# Reset zoom
			_zoom_camera(Vector2(1.5, 1.5))
			
		# Stop hover music
		if has_node("HoverMusic"):
			var music_player = get_node("HoverMusic")
			music_player.stop()
			_hover_music_playing = false
			
		# Resume ambient music
		_set_ambient_music_playing(true)
		
		# Play success sound
		var success_sfx = AudioStreamPlayer.new()
		success_sfx.stream = load("res://asset/sounds/success.mp3")
		success_sfx.bus = "SFX"
		success_sfx.volume_db = -5.0
		add_child(success_sfx)
		success_sfx.play()
		success_sfx.finished.connect(success_sfx.queue_free)

		# Play fireworks effect for 5 seconds
		_play_fireworks_sequence()

func _play_fireworks_sequence() -> void:
	# Create a timer to stop fireworks after 5 seconds
	var duration_timer = Timer.new()
	duration_timer.one_shot = true
	duration_timer.autostart = true
	duration_timer.wait_time = 5.0
	add_child(duration_timer)
	
	# Create a timer to spawn burst clusters rapidly
	var burst_timer = Timer.new()
	burst_timer.wait_time = 0.3 # Faster bursts
	burst_timer.autostart = true
	add_child(burst_timer)
	
	burst_timer.timeout.connect(func(): 
		# Spawn multiple fireworks at once for chaotic effect
		for i in range(3):
			_spawn_screen_firework()
	)
	
	# Cleanup after 5 seconds
	duration_timer.timeout.connect(func():
		burst_timer.stop()
		burst_timer.queue_free()
		duration_timer.queue_free()
	)

func _spawn_screen_firework() -> void:
	var particles = CPUParticles2D.new()
	add_child(particles)
	
	# Load texture
	var tex = load("res://asset/ui/result/paper_color.png")
	if tex:
		particles.texture = tex
		
	# Setup properties based on VictoryScreen reference
	particles.emitting = false
	particles.amount = 60 # Increased amount
	particles.one_shot = true
	particles.explosiveness = randf_range(0.9, 1.0) # Slight randomization
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 400)
	particles.initial_velocity_min = 250.0
	particles.initial_velocity_max = 650.0
	particles.angular_velocity_min = -250.0
	particles.angular_velocity_max = 250.0
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.2
	
	# Randomize Base Color for each burst to guarantee variety
	# Using HSV to get bright, vibrant colors
	particles.color = Color.from_hsv(randf(), 1.0, 1.0) 
	
	# Hue variation to make particles within the SAME burst have different colors
	particles.hue_variation_min = -1.0
	particles.hue_variation_max = 1.0
	
	# Calculate random position within the current camera view
	var cam = get_viewport().get_camera_2d()
	var center_pos = Vector2.ZERO
	if cam:
		center_pos = cam.get_screen_center_position()
	else:
		center_pos = GameManager.player.global_position
		
	var viewport_size = get_viewport().get_visible_rect().size
	# Spawn mainly in the upper 2/3 of the screen
	var offset_x = randf_range(-viewport_size.x * 0.45, viewport_size.x * 0.45)
	var offset_y = randf_range(-viewport_size.y * 0.4, viewport_size.y * 0.2)
	
	particles.global_position = center_pos + Vector2(offset_x, offset_y)
	particles.z_index = 100 # Ensure on top
	
	# Start emitting
	particles.emitting = true
	
	# Auto remove after finished
	particles.finished.connect(particles.queue_free)
	get_tree().create_timer(4.0).timeout.connect(particles.queue_free)

func _start_challenge_sequence() -> void:
	print("DEBUG: _start_challenge_sequence called")
	if _challenge_active or _challenge_completed: 
		print("DEBUG: Challenge already active or completed")
		return
	
	_challenge_completed = false
	_challenge_time = 60.0
	
	var ui = get_node_or_null("UI/ChallengeUI")
	if ui:
		print("DEBUG: UI found, making visible")
		ui.visible = true
		var arrow = ui.get_node_or_null("Arrow")
		if arrow: arrow.visible = false
		var timer_lbl = ui.get_node_or_null("TimerLabel")
		if timer_lbl: timer_lbl.visible = false
		
		# Start Countdown 3, 2, 1, START
		_run_countdown_step(3)
		
	# Zoom out camera by ~25% (1.5 -> 1.125)
	_zoom_camera(Vector2(1.125, 1.125))
	
	# Unlock camera limit
	_set_camera_limit(10000000)
	
	# Start music
	_play_hover_music()

func _run_countdown_step(number: int) -> void:
	var ui = get_node_or_null("UI/ChallengeUI")
	if not ui: return
	var lbl = ui.get_node_or_null("CountdownLabel")
	if not lbl: return
	
	lbl.visible = true
	lbl.scale = Vector2(0.5, 0.5)
	lbl.modulate.a = 0.0
	
	if number > 0:
		lbl.text = str(number)
		lbl.add_theme_color_override("font_color", Color.WHITE)
	else:
		lbl.text = "START!"
		lbl.add_theme_color_override("font_color", Color.GREEN)
	
	# Tween for pop effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 1.0, 0.2)
	
	tween.chain().tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.2)
	
	tween.chain().tween_callback(func():
		if number > 1:
			_run_countdown_step(number - 1)
		elif number == 1:
			_run_countdown_step(0) # START
		else:
			_begin_challenge_logic()
	)

func _begin_challenge_logic() -> void:
	_challenge_active = true
	var ui = get_node_or_null("UI/ChallengeUI")
	if ui:
		var timer_lbl = ui.get_node_or_null("TimerLabel")
		if timer_lbl: timer_lbl.visible = true
		var arrow = ui.get_node_or_null("Arrow")
		if arrow: arrow.visible = true

func _fail_challenge() -> void:
	_challenge_active = false
	var ui = get_node_or_null("UI/ChallengeUI")
	if ui:
		ui.visible = false
	
	# Zoom reset
	_zoom_camera(Vector2(1.5, 1.5))
	
	# Reset limit
	_set_camera_limit(3350)
	
	if GameManager.player:
		GameManager.player.take_damage(9999999)
		# Ensure death state is triggered even if take_damage doesn't handle it
		if GameManager.player.health <= 0:
			GameManager.player.fsm.change_state(GameManager.player.fsm.states.dead)

func _zoom_camera(target_zoom: Vector2, duration: float = 1.0) -> void:
	if GameManager.player and GameManager.player.has_node("Camera2D"):
		var cam = GameManager.player.get_node("Camera2D")
		var tween = create_tween()
		tween.tween_property(cam, "zoom", target_zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_camera_limit(limit: int) -> void:
	if GameManager.player and GameManager.player.has_node("Camera2D"):
		var cam = GameManager.player.get_node("Camera2D")
		cam.limit_right = limit
