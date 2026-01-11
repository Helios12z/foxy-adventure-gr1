extends Node2D

# Cutscene configuration
@export var camera_transition_duration: float = 1.5
@export var camera_transition_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var camera_transition_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var trigger_area_path: NodePath
@export var boss_path: NodePath
@export var cutscene_camera_offset: Vector2 = Vector2(0, -50)
@export var cutscene_camera_zoom: float = 1.5  # Camera zoom during cutscene (bigger = more zoomed in)

var cutscene_triggered = false
var player_camera: Camera2D = null
var player: Node2D = null
var boss: Node2D = null
var trigger_area: Area2D = null
var cutscene_camera: Camera2D = null

func _ready() -> void:
	# Get references
	if trigger_area_path and not trigger_area_path.is_empty():
		trigger_area = get_node(trigger_area_path)
	if boss_path and not boss_path.is_empty():
		boss = get_node(boss_path)

	# If not set via paths, try to find them as children
	if not trigger_area:
		for child in get_children():
			if child is Area2D:
				trigger_area = child
				break

	# Create cutscene camera
	cutscene_camera = Camera2D.new()
	cutscene_camera.zoom = Vector2(cutscene_camera_zoom, cutscene_camera_zoom)
	add_child(cutscene_camera)
	cutscene_camera.enabled = false

	# Connect trigger area (with a small delay to ensure everything is set up)
	await get_tree().process_frame

	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if cutscene_triggered:
		return

	if body.is_in_group("player") or body.is_in_group("Player"):
		# Check if cutscene has been seen before
		if Dialogic.VAR.has("KingCrabCutsceneSeen") and Dialogic.VAR.get("KingCrabCutsceneSeen"):
			return

		cutscene_triggered = true
		player = body

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
	# Wait for player to land if in air
	if player and player is CharacterBody2D:
		if not player.is_on_floor():
			# Wait until player lands
			while not player.is_on_floor():
				await get_tree().process_frame
			# Small delay after landing
			await get_tree().create_timer(0.2).timeout

	# Disable player movement
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	elif player:
		player.set_physics_process(false)

	# Switch to cutscene camera (with smooth transition)
	await _switch_to_cutscene_camera()

	# Wait a moment, then show dialogue
	await get_tree().create_timer(0.3).timeout
	_show_dialogue()

func _switch_to_cutscene_camera() -> void:
	if not cutscene_camera or not boss:
		return

	# Get current camera position
	var start_pos: Vector2
	if player_camera and player_camera.is_current():
		start_pos = player_camera.get_screen_center_position()
	else:
		start_pos = cutscene_camera.global_position

	# Calculate target position (focus on boss)
	var target_pos = boss.global_position + cutscene_camera_offset

	# Disable player camera
	if player_camera:
		player_camera.enabled = false

	# Position cutscene camera at player's current view position
	cutscene_camera.global_position = start_pos

	# Enable and make cutscene camera current
	cutscene_camera.enabled = true
	cutscene_camera.make_current()

	# Smooth transition to boss
	var tween = create_tween()
	tween.set_ease(camera_transition_ease)
	tween.set_trans(camera_transition_trans)
	tween.tween_property(cutscene_camera, "global_position", target_pos, camera_transition_duration)

	await tween.finished

func _switch_to_player_camera() -> void:
	if not player_camera:
		# Fallback: just disable cutscene camera
		if cutscene_camera:
			cutscene_camera.enabled = false
		return

	# Get target position (where player camera should be)
	var target_pos = player_camera.get_screen_center_position()

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

func _show_dialogue() -> void:
	# Change boss animation to idle (wake up)
	if boss and boss.has_method("change_animation"):
		boss.change_animation("idle")

	# Mark cutscene as seen
	Dialogic.VAR.set("KingCrabCutsceneSeen", true)

	# Skip dialog - content has been merged into king_crab_death dialog
	# Directly end cutscene
	_on_dialogue_ended()

func _on_dialogue_ended() -> void:
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

	# Trigger boss wake-up sequence
	_trigger_boss_wakeup()

func _trigger_boss_wakeup() -> void:
	if boss and boss.has_method("_handle_sleep_damage"):
		# Force the boss to wake up
		boss._sleep_health = 0
		boss.is_sleeping = false
		boss._recent_damage_times.clear()

		if boss.fsm and boss.fsm.current_state == boss.fsm.states.sleep:
			boss.fsm.change_state(boss.fsm.states.castaftersleep)

		boss.emit_signal("start_fight")

