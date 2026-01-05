extends Node2D

signal complete_moving_up

@export var rect_platform: Node2D
@export var platforms: Array[Node2D] = []              
@export var jump_markers: Array[JumpMarker2D] = []     

@export var phase_2_start_delay: float = 0.0                    

@export var left_platform: Node2D
@export var right_platform: Node2D

@export var room_bound_point_a: Marker2D
@export var room_bound_point_b: Marker2D

@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")
@onready var crack_sfx: AudioStreamPlayer2D = $"../../Sound/Craking"
@onready var water_priestess: CharacterBody2D = $"../WaterPrietest"
@onready var cracking_effect: AnimatedSprite2D = $"../../World/BossPlatformController/RectPlatform/CrackingEffect"

var is_phase_2_active: bool = false
var _intro_done: bool = false
var _phase2_started: bool = false
var _returned: bool = false
var _col_cache := {}
var _rect_platform_original_pos: Vector2
var _rect_platform_visible: bool = true

func _ready() -> void:
	randomize()
	_setup_initial_platforms()
	_connect_boss_signals()

	if rect_platform:
		_rect_platform_original_pos = rect_platform.global_position

	if cracking_effect:
		cracking_effect.visible = false
		cracking_effect.stop()

func _setup_initial_platforms() -> void:
	if rect_platform:
		rect_platform.visible = true
		rect_platform.modulate.a = 1.0
		_set_platform_collision(rect_platform, true)
		_rect_platform_visible = true

	if left_platform:
		left_platform.visible = true
		left_platform.modulate.a = 1.0
		_set_platform_collision(left_platform, true)

	if right_platform:
		right_platform.visible = true
		right_platform.modulate.a = 1.0
		_set_platform_collision(right_platform, true)

	for platform in platforms:
		if platform:
			platform.visible = false
			platform.modulate.a = 0.0
			_set_platform_collision(platform, false)

	for marker in jump_markers:
		if marker:
			marker.set_active(false)

func _connect_boss_signals() -> void:
	if not water_priestess:
		return

	if not water_priestess.start_fight.is_connected(_on_fight_start):
		water_priestess.start_fight.connect(_on_fight_start)

	if not water_priestess.into_phase2.is_connected(_on_phase_2_start):
		water_priestess.into_phase2.connect(_on_phase_2_start)

	if not water_priestess.boss_died.is_connected(_on_boss_died):
		water_priestess.boss_died.connect(_on_boss_died)

func _hide_side_platforms() -> void:
	if left_platform:
		var tw_left := create_tween()
		tw_left.tween_property(left_platform, "modulate:a", 0.0, 0.5)
		tw_left.finished.connect(func():
			if left_platform:
				left_platform.visible = false
				_set_platform_collision(left_platform, false)
		)

	if right_platform:
		var tw_right := create_tween()
		tw_right.tween_property(right_platform, "modulate:a", 0.0, 0.5)
		tw_right.finished.connect(func():
			if right_platform:
				right_platform.visible = false
				_set_platform_collision(right_platform, false)
		)

func _show_side_platforms() -> void:
	if left_platform:
		left_platform.visible = true
		if left_platform is CanvasItem:
			(left_platform as CanvasItem).modulate.a = 0.0
		_set_platform_collision(left_platform, true)

		var tw_left := create_tween()
		tw_left.tween_property(left_platform, "modulate:a", 1.0, 0.5)

	if right_platform:
		right_platform.visible = true
		if right_platform is CanvasItem:
			(right_platform as CanvasItem).modulate.a = 0.0
		_set_platform_collision(right_platform, true)

		var tw_right := create_tween()
		tw_right.tween_property(right_platform, "modulate:a", 1.0, 0.5)

func start_boss_intro() -> void:
	if _intro_done:
		return
	_intro_done = true

	if camera:
		camera.camera_shake(0.5, 24)
	if crack_sfx:
		crack_sfx.play(2.0)

	_hide_side_platforms()

func _on_fight_start() -> void:
	await get_tree().create_timer(0.75).timeout
	start_boss_intro()

func _on_phase_2_start() -> void:
	if is_phase_2_active:
		return

	is_phase_2_active = true

	# Wait 2 seconds after phase 2 starts
	await get_tree().create_timer(2.0).timeout

	# Show floating platforms FIRST (so boss always has somewhere to stand)
	_show_floating_platforms_only()

	# Enable jump markers BEFORE boss jumps
	_enable_floating_platform_markers()

	# Small delay for platforms to be ready
	await get_tree().create_timer(0.2).timeout

	# Make boss jump to a higher platform
	_make_boss_jump_to_higher_platform()

	# Wait for boss to land (approximately 1 second)
	await get_tree().create_timer(1.0).timeout

	# Then play cracking effect and destroy platform
	await _destroy_rect_platform_with_cracking()

func _show_floating_platforms_only() -> void:
	# Show floating platforms but don't enable jump markers yet
	for platform in platforms:
		platform.visible = true
		platform.modulate.a = 1.0
		_set_platform_collision(platform, true)

	# Camera shake to indicate platforms appearing
	if camera:
		camera.camera_shake(0.3, 16)

func _enable_floating_platform_markers() -> void:
	# Enable only floating platform markers (not rect platform)
	for platform in platforms:
		var markers := _get_markers_for_platform(platform)
		for marker in markers:
			if marker:
				marker.set_active(true)

func _make_boss_jump_to_higher_platform() -> void:
	if not water_priestess or not water_priestess.fsm:
		return

	# Force boss to jump state
	water_priestess.fsm.change_state(water_priestess.fsm.states.jumpstate)

func _destroy_rect_platform_with_cracking() -> void:
	if not rect_platform:
		return

	# Play cracking sound
	if crack_sfx:
		crack_sfx.play()

	# Show and play cracking effect
	if cracking_effect:
		cracking_effect.visible = true
		cracking_effect.frame = 0
		cracking_effect.play()

		# Wait for cracking animation to complete
		await cracking_effect.animation_finished

	# Hide the cracking effect
	if cracking_effect:
		cracking_effect.visible = false
		cracking_effect.stop()

	# Hide and disable the rect platform
	_hide_rect_platform()

	# Stop the crack sound
	if crack_sfx:
		crack_sfx.stop()

func _hide_rect_platform() -> void:
	if not rect_platform:
		return

	# Disable the jump marker on rect platform
	var rect_markers := _get_markers_for_platform(rect_platform)
	for marker in rect_markers:
		if marker:
			marker.set_active(false)

	# Create a tween to fade out the platform
	var tween := create_tween()
	tween.parallel().tween_property(rect_platform, "modulate:a", 0.0, 0.5)

	# Wait for fade to complete
	await tween.finished

	# Hide and disable collision
	rect_platform.visible = false
	_set_platform_collision(rect_platform, false)
	_rect_platform_visible = false

func _show_rect_platform() -> void:
	if not rect_platform:
		return

	# Show and enable collision
	rect_platform.visible = true
	_set_platform_collision(rect_platform, true)
	_rect_platform_visible = true

	# Re-enable the jump marker on rect platform
	var rect_markers := _get_markers_for_platform(rect_platform)
	for marker in rect_markers:
		if marker:
			marker.set_active(true)

	# Create a tween to fade in the platform
	var tween := create_tween()
	tween.tween_property(rect_platform, "modulate:a", 1.0, 0.5)

func _on_boss_died() -> void:
	# Restore the rect platform when boss dies
	_show_rect_platform()

func start_phase2_platforms() -> void:
	print("start phase 2 platforms")
	if _phase2_started:
		return
	_phase2_started = true

	# Enable jump markers so boss can use the platforms
	for marker in jump_markers:
		if marker:
			marker.set_active(true)

	emit_signal("complete_moving_up")

func return_platform_after_boss_dead() -> void:
	if _returned:
		return
	_returned = true
	_return_after_boss_freed()

func _return_after_boss_freed() -> void:
	# Đợi boss queue_free xong (tree_exited / instance invalid)
	await _wait_boss_freed(6.0)

	# Sau khi boss biến mất khỏi scene mới bắt đầu dọn platform
	if camera:
		camera.camera_shake(0.4, 24)
	if crack_sfx:
		crack_sfx.play(2.0)

	_cleanup_after_return()

	if crack_sfx:
		crack_sfx.stop()

func _cleanup_after_return() -> void:
	for plat in platforms:
		if plat:
			plat.visible = false
			if plat is CanvasItem:
				(plat as CanvasItem).modulate.a = 0.0
			_set_platform_collision(plat, false)

	for marker in jump_markers:
		if marker:
			marker.set_active(false)

	is_phase_2_active = false
	_phase2_started = false

	_show_side_platforms()

	for marker in jump_markers:
		if marker:
			marker.set_active(false)

	is_phase_2_active = false
	_phase2_started = false

	_show_side_platforms()

func setup_after_boss_dead_state() -> void:
	for plat in platforms:
		if plat:
			plat.visible = false
			plat.modulate.a = 0.0
			_set_platform_collision(plat, false)

	for marker in jump_markers:
		if marker:
			marker.set_active(false)

	is_phase_2_active = false
	_phase2_started = false
	_returned = false
	
func _cache_col(obj2d: CollisionObject2D) -> void:
	var id := obj2d.get_instance_id()
	if _col_cache.has(id):
		return
	_col_cache[id] = {"layer": obj2d.collision_layer, "mask": obj2d.collision_mask}

func _restore_col(obj2d: CollisionObject2D) -> void:
	var id := obj2d.get_instance_id()
	if not _col_cache.has(id):
		return
	obj2d.collision_layer = _col_cache[id].layer
	obj2d.collision_mask  = _col_cache[id].mask

func _set_platform_collision(root: Node, enabled: bool) -> void:
	if root == null:
		return

	if "collision_enabled" in root:
		root.collision_enabled = enabled

	if root is CollisionObject2D:
		var co := root as CollisionObject2D
		_cache_col(co)
		if enabled:
			_restore_col(co)
		else:
			co.collision_layer = 0
			co.collision_mask  = 0

	if root is CollisionShape2D:
		(root as CollisionShape2D).disabled = not enabled
	elif root is CollisionPolygon2D:
		(root as CollisionPolygon2D).disabled = not enabled

	for child in root.get_children():
		_set_platform_collision(child, enabled)

func _get_markers_for_platform(platform: Node2D) -> Array[JumpMarker2D]:
	var associated_markers: Array[JumpMarker2D] = []
	if not platform:
		return associated_markers

	for marker in jump_markers:
		if marker and marker.get_parent() == platform:
			associated_markers.append(marker)

	return associated_markers

func get_active_markers() -> Array[JumpMarker2D]:
	var active_markers: Array[JumpMarker2D] = []
	for marker in jump_markers:
		if marker and marker.is_active:
			active_markers.append(marker)
	return active_markers

func force_activate_all_markers() -> void:
	for marker in jump_markers:
		if marker:
			marker.set_active(true)

func force_deactivate_all_markers() -> void:
	for marker in jump_markers:
		if marker:
			marker.set_active(false)
			
func _wait_boss_freed(timeout_sec: float = 5.0) -> void:
	if water_priestess == null:
		return

	var t := 0.0
	while is_instance_valid(water_priestess) and t < timeout_sec:
		await get_tree().process_frame
		t += 1.0 / max(1.0, Engine.get_frames_per_second())
