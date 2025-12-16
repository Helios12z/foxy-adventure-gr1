extends Node2D
@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss: CharacterBody2D = $Boss3



func _enter_tree() -> void:
	GameManager.current_stage = self

func _ready() -> void:
	# Try to respawn at portal (door) first
	var spawned_at_portal = GameManager.respawn_at_portal()

	if not spawned_at_portal:
		GameManager.respawn_at_checkpoint()

	# Don't lock player movement at start - let boss intro handle it
	# if GameManager.player:
	#	GameManager.player.set_can_move(false)
	#	print("[Boss3 Level] Player locked from start")

	# Ensure player always respawns at the entrance door during boss fight
	var entrance_door = get_node_or_null("Teleport")
	if entrance_door and is_instance_valid(entrance_door):
		# Save a checkpoint at the entrance door position for respawning
		if spawned_at_portal and GameManager.player:
			# Player just entered through door - save checkpoint here
			var door_checkpoint_id = "boss3_entrance"
			GameManager.current_checkpoint_id = door_checkpoint_id
			GameManager.save_checkpoint(door_checkpoint_id)
			GameManager.save_checkpoint_data()
			print("[Boss3 Level] Saved entrance door checkpoint at: ", entrance_door.global_position)

			# Fade out the entrance door after teleportation
			_fade_entrance_door(entrance_door)

	_setup_boss_alive_state()
	_setup_camera_for_boss3()

	# Fade out the Door node AFTER scene is fully loaded and visible
	if spawned_at_portal:
		var door_node = get_node_or_null("Door")
		if door_node and is_instance_valid(door_node):
			# Wait for loading screen to finish and scene to be visible
			await get_tree().create_timer(2.0).timeout
			print("[Boss3 Level] Fading out Door node after arrival")
			_fade_entrance_door(door_node)


func _setup_boss_alive_state() -> void:
	boss_hud.set_boss(boss)
	print("we set boss")

	# Connect to boss intro_finished signal to trigger dialogue instead of starting fight
	if not boss.intro_finished.is_connected(_on_boss_intro_finished):
		boss.intro_finished.connect(_on_boss_intro_finished)

	# Connect to boss cutscene_ready signal to start the ending cutscene
	if not boss.cutscene_ready.is_connected(_on_boss_cutscene_ready):
		boss.cutscene_ready.connect(_on_boss_cutscene_ready)

func _on_boss_intro_finished() -> void:
	print("[Level Boss 3] Boss intro finished! Starting dialogue...")

	# Lock player during dialogue
	if GameManager.player:
		GameManager.player.set_can_move(false)
		print("[Boss3 Level] Player locked for dialogue")

	# Keep boss invulnerable during dialogue
	if boss:
		boss.is_invulnerable = true
		print("[Boss3 Level] Boss invulnerable during dialogue")

	# Start the Water Goddess awakening dialogue
	Dialogic.start("water_goddess_awakening")
	# Wait for dialogue to finish before starting fight
	await Dialogic.timeline_ended
	print("[Level Boss 3] Dialogue finished! Starting fight...")

	# Re-enable player movement
	if GameManager.player:
		GameManager.player.set_can_move(true)
		print("[Level Boss 3] Player movement enabled")

	# Start the boss fight (this will initialize FSM and make boss vulnerable)
	if boss and boss.has_method("start_boss_fight"):
		boss.start_boss_fight()
		print("[Level Boss 3] Boss fight started!")
	else:
		# Fallback for older boss scripts
		if boss:
			boss.is_invulnerable = false
			print("[Level Boss 3] Boss vulnerable (fallback)")

	boss_hud._on_boss_start_fighting()
	print("[Level Boss 3] HUD visible now: ", boss_hud.visible)

func _setup_camera_for_boss3() -> void:
	# Use Phase3Camera for the whole level instead of player's camera
	var phase3_camera = get_tree().get_first_node_in_group("Phase3Camera")
	if phase3_camera and phase3_camera.has_method("activate"):
		print("[Level Boss 3] Activating Phase3Camera for entire level...")
		var player_node = get_tree().get_first_node_in_group("Player")
		if player_node:
			phase3_camera.activate(player_node)
			print("[Level Boss 3] Phase3Camera activated successfully")
		else:
			print("[Level Boss 3] ERROR: Player not found")
	else:
		print("[Level Boss 3] WARNING: Phase3Camera not found, using player camera as fallback")
		# Fallback to old behavior
		var player_node = get_tree().get_first_node_in_group("Player")
		if not player_node:
			return

		var camera = player_node.get_node_or_null("Camera2D")
		if not camera:
			return

		camera.zoom = Vector2(1.3, 1.3)
		camera.offset = Vector2(0, 50)
		camera.limit_left = -100
		camera.limit_right = 700
		camera.limit_top = -1000
		camera.limit_bottom = -200
		print("[Level Boss 3] Player camera adjusted with limits for boss fight")

func _setup_boss_defeated_state() -> void:
	if is_instance_valid(boss):
		boss.queue_free()

	if boss_hud and boss_hud.has_method("reset"):
		boss_hud.reset()

## Fade out the entrance door after player teleports in
func _fade_entrance_door(door: Node2D) -> void:
	if not door:
		return

	# Find the sprite or animated sprite in the door
	var sprite = null
	for child in door.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			sprite = child
			break

	if not sprite:
		# Try to get the door's own sprite if it has one
		if door is Sprite2D or door is AnimatedSprite2D:
			sprite = door

	if sprite:
		# Create fade out tween
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

		print("[Boss3 Level] Fading out entrance door")
	else:
		print("[Boss3 Level] Warning: Could not find sprite to fade in door")

## Called when boss death sequence is complete and ready for cutscene
func _on_boss_cutscene_ready() -> void:
	print("[Level Boss 3] Boss cutscene ready - starting ending cutscene")
	await _play_ending_cutscene()
	print("[Level Boss 3] Ending cutscene complete")

## Ending cutscene after boss dies
func _play_ending_cutscene() -> void:
	print("[Boss3 Cutscene] Starting ending cutscene")

	# Get references
	var player = GameManager.player
	if not player:
		print("[Boss3 Cutscene] ERROR: Player not found")
		return

	var anchor5 = get_node_or_null("BossAnchors/Anchor5")
	var anchor6 = get_node_or_null("BossAnchors/Anchor6")
	var anchor7 = get_node_or_null("BossAnchors/Anchor7")

	if not anchor5 or not anchor6 or not anchor7:
		print("[Boss3 Cutscene] ERROR: Anchors not found")
		return

	# Take control from player and make them invulnerable
	player.set_can_move(false)
	player.is_invulnerable = true
	print("[Boss3 Cutscene] Player control disabled and made invulnerable")

	await get_tree().create_timer(1.0).timeout

	# 0. Player reflects on killing crab & turtle (miserable dialogue)
	print("[Boss3 Cutscene] Step 0: Player reflects on killing bosses")
	Dialogic.start("boss3_aftermath_reflection")
	await Dialogic.timeline_ended
	print("[Boss3 Cutscene] Reflection dialogue finished")

	await get_tree().create_timer(1.0).timeout

	# 1. Door appears at Anchor7
	print("[Boss3 Cutscene] Step 1: Door appears at Anchor7")
	var DoorScene = preload("res://levels/objects/door/door_map3.tscn")
	var cutscene_door = DoorScene.instantiate()
	add_child(cutscene_door)
	cutscene_door.global_position = anchor7.global_position
	cutscene_door.modulate.a = 0.0  # Start invisible

	# Fade in the door
	var tween1 = create_tween()
	tween1.tween_property(cutscene_door, "modulate:a", 1.0, 0.5)
	await tween1.finished
	await get_tree().create_timer(0.5).timeout

	# 2. Door plays "door_opened" animation
	print("[Boss3 Cutscene] Step 2: Door opens")
	var door_sprite = cutscene_door.get_node_or_null("AnimatedSprite2D")
	if door_sprite:
		if door_sprite.sprite_frames.has_animation("door_opened"):
			door_sprite.play("door_opened")
		else:
			# Fallback to opening if door_opened doesn't exist
			door_sprite.play("opening")
			await door_sprite.animation_finished
	await get_tree().create_timer(0.5).timeout

	# 3. Player self-talk dialogue
	print("[Boss3 Cutscene] Step 3: Player self-talk")
	Dialogic.start("boss3_door_self_talk")
	await Dialogic.timeline_ended
	print("[Boss3 Cutscene] Self-talk dialogue finished")

	# 4. Fox moves toward door
	var distance_to_door = player.global_position.distance_to(cutscene_door.global_position)
	if distance_to_door > 50:
		print("[Boss3 Cutscene] Step 4: Fox moves toward door")
		# Make player face the door
		if player.global_position.x > cutscene_door.global_position.x:
			player.direction = -1
		else:
			player.direction = 1

		# Move player toward door
		var target_pos = cutscene_door.global_position + Vector2(0, 10)
		var tween2 = create_tween()
		tween2.tween_property(player, "global_position", target_pos, 1.5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		await tween2.finished

	await get_tree().create_timer(0.5).timeout

	# 5. Dark blue waves burst at Anchor5
	print("[Boss3 Cutscene] Step 5: Dark blue waves burst at Anchor5")
	var DarkBlueEnergyScene = preload("res://scenes/bosses/boss3/DarkBlueEnergy.tscn")

	# Create 5 wave bursts
	for i in range(5):
		var wave = DarkBlueEnergyScene.instantiate()
		add_child(wave)
		wave.global_position = anchor5.global_position

		# Random direction for burst
		var angle = randf_range(0, TAU)
		var burst_distance = randf_range(50, 150)
		var target_pos = anchor5.global_position + Vector2(cos(angle), sin(angle)) * burst_distance

		# Animate burst
		var tween_burst = create_tween()
		tween_burst.tween_property(wave, "global_position", target_pos, 0.3)
		tween_burst.parallel().tween_property(wave, "modulate:a", 0.0, 0.5)

		await get_tree().create_timer(0.1).timeout

	await get_tree().create_timer(0.5).timeout

	# 6. DarkBlueEnergy appears and moves from Anchor5 to Anchor6
	print("[Boss3 Cutscene] Step 6: Dark energy appears and moves from Anchor5 to Anchor6")
	var dark_energy = DarkBlueEnergyScene.instantiate()
	add_child(dark_energy)
	dark_energy.global_position = anchor5.global_position

	# Play dark blue energy sound
	var dark_energy_sound = AudioStreamPlayer.new()
	add_child(dark_energy_sound)
	dark_energy_sound.stream = load("res://asset/sounds/boss 3/dark_blue_energy.mp3")
	dark_energy_sound.play()
	print("[Boss3 Cutscene] Playing dark_blue_energy.mp3")

	# Start the default animation (spinning/rotating)
	var energy_sprite = dark_energy.get_node_or_null("AnimatedSprite2D")
	if energy_sprite:
		energy_sprite.play("default")

	# Smoothly move down from Anchor5 to Anchor6
	var tween3 = create_tween()
	tween3.tween_property(dark_energy, "global_position", anchor6.global_position, 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween3.finished

	await get_tree().create_timer(0.5).timeout

	# 7. Player turns around to look at energy
	print("[Boss3 Cutscene] Step 7: Player turns to look at energy")
	if player.global_position.x < dark_energy.global_position.x:
		player.direction = 1
	else:
		player.direction = -1

	await get_tree().create_timer(0.5).timeout

	# Fade out the door since we're not using it anymore
	var tween_door_fade = create_tween()
	tween_door_fade.tween_property(cutscene_door, "modulate:a", 0.0, 1.0)

	# 8. Energy whispers dialogue
	print("[Boss3 Cutscene] Step 8: Energy whispers")
	Dialogic.start("boss3_energy_whisper")
	await Dialogic.timeline_ended
	print("[Boss3 Cutscene] Energy whisper dialogue finished")

	await get_tree().create_timer(0.5).timeout

	# 9. Foxy is attracted and jumps to energy with arc
	print("[Boss3 Cutscene] Step 9: Foxy is attracted and jumps to energy")

	# Calculate jump arc
	var start_pos = player.global_position
	var end_pos = dark_energy.global_position
	var jump_height = 80.0  # How high the arc goes
	var jump_duration = 1.2

	# Create arc jump using parallel tweens
	var tween4 = create_tween()
	# Move horizontally
	tween4.tween_property(player, "global_position:x", end_pos.x, jump_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	# Move vertically with arc (up then down)
	tween4.parallel().tween_method(
		func(t: float):
			# Parabolic arc: peaks at t=0.5
			var arc = -4.0 * jump_height * t * (t - 1.0)  # Parabola formula
			var new_y = start_pos.y + (end_pos.y - start_pos.y) * t - arc
			player.global_position.y = new_y,
		0.0,
		1.0,
		jump_duration
	)

	await tween4.finished

	await get_tree().create_timer(0.3).timeout

	# 10. Foxy absorbs the dark power - energy fades out
	print("[Boss3 Cutscene] Step 10: Foxy absorbs dark power")

	# Fade out the dark energy as it's absorbed
	var tween_absorb = create_tween()
	tween_absorb.tween_property(dark_energy, "modulate:a", 0.0, 1.0)
	await tween_absorb.finished
	dark_energy.queue_free()

	await get_tree().create_timer(0.5).timeout

	# 11. Screen flashes dark blue 20 times (intervals get shorter)
	print("[Boss3 Cutscene] Step 11: Screen flash dark blue 20 times")

	# Create a CanvasLayer to ensure overlay is always on top and fills screen
	var overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100  # High layer to be on top
	add_child(overlay_layer)

	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color(0.0, 0.0, 0.5, 0.0)  # Dark blue, start transparent
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(flash_overlay)

	# Flash 20 times with decreasing intervals (shorter intervals)
	var flash_intervals = [0.4, 0.35, 0.3, 0.28, 0.25, 0.23, 0.2, 0.18, 0.15, 0.13, 0.12, 0.11, 0.1, 0.09, 0.08, 0.07, 0.06, 0.05, 0.04, 0.03]
	for i in range(20):
		var tween_flash = create_tween()
		tween_flash.tween_property(flash_overlay, "color:a", 0.8, 0.08)
		tween_flash.tween_property(flash_overlay, "color:a", 0.0, 0.08)
		await tween_flash.finished

		# Wait before next flash (decreasing interval)
		if i < 19:  # Don't wait after the last flash
			await get_tree().create_timer(flash_intervals[i]).timeout

	await get_tree().create_timer(0.3).timeout

	# 12. Switch player to dark animation after flashes
	print("[Boss3 Cutscene] Step 12: Foxy turns dark")

	# Disable player physics processing to prevent animation override
	player.set_physics_process(false)
	player.set_process(false)

	# Get all the sprite nodes
	var main_sprite = player.get_node_or_null("Direction/AnimatedSprite2D")
	var hat_sprite = player.get_node_or_null("Direction/HatAnimatedSprite2D")
	var blade_sprite = player.get_node_or_null("Direction/BladeAnimatedSprite2D")

	# Play dark animation on main sprite
	if main_sprite:
		# Make sure main sprite is visible
		main_sprite.visible = true

		if main_sprite.sprite_frames and main_sprite.sprite_frames.has_animation("dark"):
			main_sprite.play("dark")
			print("[Boss3 Cutscene] Playing 'dark' on main sprite")
		else:
			# Fallback to idle if dark doesn't exist
			print("[Boss3 Cutscene] WARNING: 'dark' animation not found in main sprite_frames")
			if main_sprite.sprite_frames:
				print("[Boss3 Cutscene] Available animations: ", main_sprite.sprite_frames.get_animation_names())
				# Play idle as fallback
				if main_sprite.sprite_frames.has_animation("idle"):
					main_sprite.play("idle")
					print("[Boss3 Cutscene] Playing 'idle' as fallback")
	else:
		print("[Boss3 Cutscene] ERROR: main_sprite not found!")

	# Hide hat and blade sprites during dark transformation
	if hat_sprite and hat_sprite.visible:
		hat_sprite.visible = false
		print("[Boss3 Cutscene] Hiding hat sprite")

	if blade_sprite and blade_sprite.visible:
		blade_sprite.visible = false
		print("[Boss3 Cutscene] Hiding blade sprite")

	await get_tree().create_timer(0.5).timeout

	# 13. Create new camera and zoom into foxy for dark_and_smile
	print("[Boss3 Cutscene] Step 13: Creating zoom camera and playing dark_and_smile")

	# Disable existing cameras
	var phase3_camera = get_tree().get_first_node_in_group("Phase3Camera")
	if phase3_camera:
		phase3_camera.enabled = false
		print("[Boss3 Cutscene] Disabled Phase3Camera")

	var player_camera = player.get_node_or_null("Camera2D")
	if player_camera:
		player_camera.enabled = false
		print("[Boss3 Cutscene] Disabled player camera")

	# Create a new camera for the zoom
	var zoom_camera = Camera2D.new()
	player.add_child(zoom_camera)
	zoom_camera.enabled = true
	zoom_camera.position = Vector2.ZERO  # Centered on player
	zoom_camera.zoom = Vector2(1.3, 1.3)  # Start at current zoom level
	print("[Boss3 Cutscene] Created new zoom camera")

	# Smooth zoom into player
	var tween_zoom = create_tween()
	tween_zoom.tween_property(zoom_camera, "zoom", Vector2(3.0, 3.0), 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween_zoom.finished
	print("[Boss3 Cutscene] Zoomed into foxy")

	await get_tree().create_timer(0.3).timeout

	# Play dark_and_smile animation
	if main_sprite:
		if main_sprite.sprite_frames and main_sprite.sprite_frames.has_animation("dark_and_smile"):
			main_sprite.play("dark_and_smile")
			print("[Boss3 Cutscene] Playing 'dark_and_smile' animation")
		else:
			print("[Boss3 Cutscene] WARNING: 'dark_and_smile' animation not found, keeping 'dark'")

	# Play smile sound
	var smile_sound = AudioStreamPlayer.new()
	add_child(smile_sound)
	smile_sound.stream = load("res://asset/sounds/boss 3/smile.mp3")
	smile_sound.play()
	print("[Boss3 Cutscene] Playing smile.mp3")

	await get_tree().create_timer(2.5).timeout

	# Keep the zoom camera active (don't re-enable old cameras)

	# 14. Black screen with white text and outro music
	print("[Boss3 Cutscene] Step 14: Black screen with text and outro music")
	flash_overlay.color = Color(0, 0, 0, 0)
	var tween7 = create_tween()
	tween7.tween_property(flash_overlay, "color:a", 1.0, 1.5)
	await tween7.finished

	# Play outro music
	var outro_sound = AudioStreamPlayer.new()
	add_child(outro_sound)
	outro_sound.stream = load("res://asset/sounds/boss 3/outro.mp3")
	outro_sound.play()
	print("[Boss3 Cutscene] Playing outro.mp3")

	await get_tree().create_timer(0.5).timeout

	# Add text to the same overlay layer
	var text_label = Label.new()
	text_label.text = "Kẻ dũng sĩ giết được Ác Long, cuối cùng sẽ thấy trên người mình mọc vảy. \n\nBởi vì ngai vàng của bóng tối... chưa bao giờ chấp nhận bỏ trống."
	text_label.add_theme_font_size_override("font_size", 32)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_label.modulate.a = 0.0
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(text_label)

	var tween8 = create_tween()
	tween8.tween_property(text_label, "modulate:a", 1.0, 2.0)
	await tween8.finished

	# Cleanup boss (but keep the black screen and text forever)
	print("[Boss3 Cutscene] Cutscene complete - black screen remains until player closes game")
	if boss and is_instance_valid(boss):
		boss.queue_free()

	# Black screen with text stays forever - player must close the game
	# The overlay_layer is NOT freed, so it remains on screen
	# Player control is NOT re-enabled
