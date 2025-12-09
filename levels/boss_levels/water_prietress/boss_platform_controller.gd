extends Node2D

signal complete_moving_up

@export var rect_platform: Node2D
@export var platforms: Array[Node2D] = []              # Floating platforms (phase 2 static)
@export var jump_markers: Array[JumpMarker2D] = []     # JumpMarker con của từng platform

@export var phase_2_start_delay: float = 0.0
@export var rise_time: float = 0.5                     # Thời gian fade-in floating platforms

@export var left_platform: Node2D
@export var right_platform: Node2D

@export var room_bound_point_a: Marker2D
@export var room_bound_point_b: Marker2D

@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")
@onready var crack_sfx: AudioStreamPlayer2D = $"../../Sound/Craking"
@onready var water_priestess: CharacterBody2D = $"../WaterPrietest"

var is_phase_2_active: bool = false

var _intro_done: bool = false
var _phase2_started: bool = false
var _returned: bool = false

var _platform_start_positions: Dictionary = {} # key = Node2D, value = Vector2


func _ready() -> void:
	randomize()
	_store_platform_positions()
	_setup_initial_platforms()
	_connect_boss_signals()


# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------

func _store_platform_positions() -> void:
	if rect_platform:
		_platform_start_positions[rect_platform] = rect_platform.global_position

	for platform in platforms:
		if platform:
			_platform_start_positions[platform] = platform.global_position


func _setup_initial_platforms() -> void:
	# Rect platform phase 1
	if rect_platform:
		rect_platform.visible = true
		rect_platform.modulate.a = 1.0
		_set_platform_collision(rect_platform, true)

	# Side platforms (biên map)
	if left_platform:
		left_platform.visible = true
		left_platform.modulate.a = 1.0
		_set_platform_collision(left_platform, true)

	if right_platform:
		right_platform.visible = true
		right_platform.modulate.a = 1.0
		_set_platform_collision(right_platform, true)

	# Floating platforms phase 2: ẩn hết ban đầu
	for platform in platforms:
		if platform:
			platform.visible = false
			platform.modulate.a = 0.0
			_set_platform_collision(platform, false)

	# Tắt marker ban đầu (phase 1 không dùng)
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


# -------------------------------------------------------------------
# Side platforms show / hide
# -------------------------------------------------------------------

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
		left_platform.modulate.a = 0.0
		_set_platform_collision(left_platform, true)
		var tw_left := create_tween()
		tw_left.tween_property(left_platform, "modulate:a", 1.0, 0.5)

	if right_platform:
		right_platform.visible = true
		right_platform.modulate.a = 0.0
		_set_platform_collision(right_platform, true)
		var tw_right := create_tween()
		tw_right.tween_property(right_platform, "modulate:a", 1.0, 0.5)


# -------------------------------------------------------------------
# Boss lifecycle
# -------------------------------------------------------------------

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
	print("start fight")
	await get_tree().create_timer(0.75).timeout
	start_boss_intro()


func _on_phase_2_start() -> void:
	print("on phase 2 started")
	if is_phase_2_active:
		return

	is_phase_2_active = true

	if phase_2_start_delay > 0.0:
		await get_tree().create_timer(phase_2_start_delay).timeout

	start_phase2_platforms()


func start_phase2_platforms() -> void:
	if _phase2_started:
		return
	_phase2_started = true

	if camera:
		camera.camera_shake(0.4, 24)
	if crack_sfx:
		crack_sfx.play(2.0)

	# Rect platform giữ nguyên như editor
	if rect_platform:
		if _platform_start_positions.has(rect_platform):
			rect_platform.global_position = _platform_start_positions[rect_platform]
		rect_platform.visible = true
		rect_platform.modulate.a = 1.0
		_set_platform_collision(rect_platform, true)

	# Bật tất cả floating platforms ở đúng vị trí inspector, static
	for platform in platforms:
		if platform:
			if _platform_start_positions.has(platform):
				platform.global_position = _platform_start_positions[platform]

			platform.visible = true
			platform.modulate.a = 0.0
			_set_platform_collision(platform, true)

			var tw := create_tween()
			tw.tween_property(
				platform,
				"modulate:a",
				1.0,
				rise_time
			)

	# Bật toàn bộ jump markers để boss có thể dùng để nhảy
	for marker in jump_markers:
		if marker:
			marker.set_active(true)

	emit_signal("complete_moving_up")
	if crack_sfx:
		crack_sfx.stop()


# -------------------------------------------------------------------
# Boss dead / reset
# -------------------------------------------------------------------

func return_platform_after_boss_dead() -> void:
	if _returned:
		return
	_returned = true

	if camera:
		camera.camera_shake(0.4, 24)
	if crack_sfx:
		crack_sfx.play(2.0)

	_cleanup_after_return()


func _cleanup_after_return() -> void:
	if crack_sfx:
		crack_sfx.stop()

	# Ẩn toàn bộ floating platforms
	for plat in platforms:
		if plat:
			plat.visible = false
			plat.modulate.a = 0.0
			_set_platform_collision(plat, false)

	# Tắt toàn bộ markers
	for marker in jump_markers:
		if marker:
			marker.set_active(false)

	is_phase_2_active = false
	_phase2_started = false

	_restore_main_platforms()


func _restore_main_platforms() -> void:
	_show_side_platforms()

	if rect_platform:
		if _platform_start_positions.has(rect_platform):
			rect_platform.global_position = _platform_start_positions[rect_platform]

		rect_platform.visible = true
		rect_platform.modulate.a = 1.0
		_set_platform_collision(rect_platform, true)


func setup_after_boss_dead_state() -> void:
	# Dùng khi reload scene / reset fight
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

	_restore_main_platforms()


# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

func _set_platform_collision(root: Node, enabled: bool) -> void:
	if root == null:
		return

	if "collision_enabled" in root:
		root.collision_enabled = enabled

	for child in root.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = not enabled
		elif child.get_child_count() > 0:
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
