extends Node2D

# Cutscene configuration
@export var npc_walk_distance: float = 100.0
@export var npc_walk_speed: float = 50.0
@export var camera_transition_duration: float = 1.5
@export var camera_transition_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var camera_transition_trans: Tween.TransitionType = Tween.TRANS_CUBIC

var cutscene_triggered = false
var player_camera: Camera2D = null
var player: Node2D = null
var original_cutscene_camera_pos: Vector2

# Node references (auto-assigned from scene)
@onready var cutscene_camera: Camera2D = $Camera2DCutSceneWaterFairyAppears
@onready var water_fairy_door: AnimatedSprite2D = $WaterFairyDoor/AnimatedSprite2D
@onready var water_fairy_npc: Node2D = $WaterFairy
@onready var trigger_area: Area2D = $FoxyReachCutScene

func _ready() -> void:
	# Debug: Check node references
	print("[Cutscene] Ready - Door: ", water_fairy_door, " NPC: ", water_fairy_npc)

	# Store original cutscene camera position
	if cutscene_camera:
		original_cutscene_camera_pos = cutscene_camera.global_position

	# Hide door and NPC initially
	if water_fairy_door:
		water_fairy_door.visible = false
	if water_fairy_npc:
		water_fairy_npc.visible = false

	# Connect trigger area
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if cutscene_triggered:
		return

	if body.is_in_group("player"):
		cutscene_triggered = true
		player = body

		# Check if the water fairy cutscene has been seen before
		if Dialogic.VAR.has("WaterFairyCutsceneSeen") and Dialogic.VAR.get("WaterFairyCutsceneSeen"):
			print("[Cutscene] Water fairy cutscene already seen, skipping...")
			# Just show the water fairy without the cutscene
			if water_fairy_npc:
				water_fairy_npc.visible = true
			return

		# Find player camera
		player_camera = _find_player_camera()

		# Start cutscene
		_start_cutscene()

func _find_player_camera() -> Camera2D:
	if player:
		# Look for camera in player node
		for child in player.get_children():
			if child is Camera2D:
				return child
	return null

func _start_cutscene() -> void:
	# Disable player movement
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	elif player:
		player.set_physics_process(false)

	# Switch to cutscene camera (with smooth transition)
	await _switch_to_cutscene_camera()

	# Wait a moment, then show door
	await get_tree().create_timer(0.3).timeout
	_show_and_open_door()

func _switch_to_cutscene_camera() -> void:
	if not cutscene_camera:
		return

	# Get current camera position (from player camera or cutscene camera)
	var start_pos: Vector2
	if player_camera and player_camera.is_current():
		start_pos = player_camera.get_screen_center_position()
	else:
		start_pos = cutscene_camera.global_position

	# Disable player camera
	if player_camera:
		player_camera.enabled = false

	# Position cutscene camera at player's current view position
	cutscene_camera.global_position = start_pos

	# Enable and make cutscene camera current
	cutscene_camera.enabled = true
	cutscene_camera.make_current()

	print("[Cutscene] Switching to cutscene camera with smooth transition")

	# Smooth transition to cutscene target position
	var tween = create_tween()
	tween.set_ease(camera_transition_ease)
	tween.set_trans(camera_transition_trans)
	tween.tween_property(cutscene_camera, "global_position", original_cutscene_camera_pos, camera_transition_duration)

	await tween.finished
	print("[Cutscene] Camera transition complete")

func _switch_to_player_camera() -> void:
	if not player_camera:
		# Fallback: just disable cutscene camera
		if cutscene_camera:
			cutscene_camera.enabled = false
		return

	# Get target position (where player camera should be)
	var target_pos = player_camera.get_screen_center_position()

	print("[Cutscene] Switching back to player camera with smooth transition")

	# Smooth transition from cutscene camera position to player camera position
	if cutscene_camera:
		var tween = create_tween()
		tween.set_ease(camera_transition_ease)
		tween.set_trans(camera_transition_trans)
		tween.tween_property(cutscene_camera, "global_position", target_pos, camera_transition_duration * 0.8)

		await tween.finished

		# Now disable cutscene camera
		cutscene_camera.enabled = false

	# Re-enable player camera
	player_camera.enabled = true
	player_camera.make_current()

	print("[Cutscene] Player camera restored")

func _show_and_open_door() -> void:
	print("[Cutscene] Showing and opening door")
	if not water_fairy_door:
		print("[Cutscene] WARNING: Door not found, skipping to NPC spawn")
		_spawn_npc()
		return

	# Show door
	water_fairy_door.visible = true
	water_fairy_door.play("door_closed")
	print("[Cutscene] Door visible, playing door_closed animation")

	# Wait a bit, then play opening animation
	await get_tree().create_timer(0.3).timeout
	water_fairy_door.play("door_opened")
	print("[Cutscene] Playing door_opened animation")

	# Wait for opening animation to finish
	await water_fairy_door.animation_finished
	print("[Cutscene] Door animation finished")

	# Spawn NPC
	_spawn_npc()

func _spawn_npc() -> void:
	print("[Cutscene] Spawning NPC - NPC node: ", water_fairy_npc)
	if not water_fairy_npc:
		print("[Cutscene] ERROR: NPC not found! Skipping to dialogue")
		_show_dialogue()
		return

	# Show NPC at door position
	water_fairy_npc.visible = true
	print("[Cutscene] NPC visible set to true at position: ", water_fairy_npc.global_position)

	if water_fairy_npc.has_node("AnimatedSprite2D"):
		water_fairy_npc.get_node("AnimatedSprite2D").play("idle")
		print("[Cutscene] Playing idle animation")
	else:
		print("[Cutscene] WARNING: AnimatedSprite2D not found in NPC")

	# Wait a moment
	await get_tree().create_timer(0.3).timeout

	# Walk NPC to the left
	_walk_npc_left()

func _walk_npc_left() -> void:
	print("[Cutscene] Walking NPC left")
	if not water_fairy_npc:
		print("[Cutscene] ERROR: NPC lost during walk!")
		_show_dialogue()
		return

	var start_pos = water_fairy_npc.global_position
	var target_pos = start_pos + Vector2(-npc_walk_distance, 0)
	print("[Cutscene] Walking from ", start_pos, " to ", target_pos)

	# Flip sprite to face left if needed
	if water_fairy_npc.has_node("AnimatedSprite2D"):
		var sprite = water_fairy_npc.get_node("AnimatedSprite2D")
		sprite.flip_h = true  # Set to true if you want to face left

	# Use tween to move NPC
	var tween = create_tween()
	var duration = npc_walk_distance / npc_walk_speed
	print("[Cutscene] Tween duration: ", duration, " seconds")
	tween.tween_property(water_fairy_npc, "global_position", target_pos, duration)

	# Wait for movement to complete
	await tween.finished
	print("[Cutscene] Walk completed, final position: ", water_fairy_npc.global_position)

	# Show dialogue
	_show_dialogue()

func _show_dialogue() -> void:
	# Mark cutscene as seen
	Dialogic.VAR.set("WaterFairyCutsceneSeen", true)

	# Start Dialogic timeline with water fairy self-talk
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	Dialogic.start("water_fairy_self_talk")

func _on_dialogue_ended() -> void:
	# Disconnect signal
	if Dialogic.timeline_ended.is_connected(_on_dialogue_ended):
		Dialogic.timeline_ended.disconnect(_on_dialogue_ended)

	# End cutscene
	_end_cutscene()

func _end_cutscene() -> void:
	# Switch back to player camera (with smooth transition)
	await _switch_to_player_camera()

	# Re-enable player movement
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)
	elif player:
		player.set_physics_process(true)

	print("[Cutscene] Cutscene ended")
