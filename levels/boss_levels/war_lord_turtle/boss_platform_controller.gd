extends Node2D

signal complete_moving_up

@onready var rect_platform: TileMapLayer = $RectPlatform
@onready var floating_platform: TileMapLayer = $FloatingPlatform
@onready var wall_platform: TileMapLayer = $WallPlatform
@onready var left_platform: TileMapLayer = $LeftPlatform
@onready var right_platform: TileMapLayer = $RightPlatform

@export var rise_height: float = 200.0
@export var rise_time: float = 3.5

@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")
@onready var crack_sfx: AudioStreamPlayer2D = $"../../Sound/Craking"

var _intro_done := false
var _phase2_started := false
var _returned := false

var _floating_start_pos: Vector2

func _ready() -> void:
	assert(rect_platform != null)
	assert(left_platform != null)
	assert(floating_platform != null)
	assert(wall_platform != null)
	assert(right_platform != null)

	_floating_start_pos = floating_platform.global_position

	rect_platform.visible = true
	_set_platform_collision(rect_platform, true)

	left_platform.visible = true
	_set_platform_collision(left_platform, true)

	floating_platform.visible = false
	_set_platform_collision(floating_platform, false)

	wall_platform.visible = false
	_set_platform_collision(wall_platform, false)

	right_platform.visible = false
	_set_platform_collision(right_platform, false)

func start_boss_intro() -> void:
	if _intro_done:
		return
	_intro_done = true

	if camera:
		camera.camera_shake(0.5, 24)
	if crack_sfx:
		crack_sfx.play(2.0)

	left_platform.visible = false
	_set_platform_collision(left_platform, false)

	wall_platform.visible = true
	_set_platform_collision(wall_platform, true)

func start_phase2_platforms() -> void:
	if _phase2_started:
		return
	_phase2_started = true

	floating_platform.visible = true
	_set_platform_collision(floating_platform, true)

	if camera:
		camera.camera_shake(0.4, 24)
	if crack_sfx:
		crack_sfx.play(2.0)

	var tw := create_tween()
	tw.tween_property(
		floating_platform,
		"global_position:y",
		_floating_start_pos.y - rise_height,
		rise_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tw.finished.connect(func ():
		emit_signal("complete_moving_up")
		if crack_sfx:
			crack_sfx.stop()
	)

func return_platform_after_boss_dead() -> void:
	if _returned:
		return
	_returned = true

	if camera:
		camera.camera_shake(0.4, 24)
	if crack_sfx:
		crack_sfx.play(2.0)

	var tw := create_tween()
	tw.set_parallel(true)

	tw.tween_property(
		floating_platform,
		"global_position:y",
		_floating_start_pos.y,
		rise_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	tw.finished.connect(func ():
		if crack_sfx:
			crack_sfx.stop()

		floating_platform.visible = false
		_set_platform_collision(floating_platform, false)

		wall_platform.visible = false
		_set_platform_collision(wall_platform, false)

		left_platform.visible = true
		_set_platform_collision(left_platform, true)

		right_platform.visible = true
		_set_platform_collision(right_platform, true)
	)


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
			
func setup_after_boss_dead_state() -> void:
	left_platform.visible = true
	_set_platform_collision(left_platform, true)
	right_platform.visible = true 
	_set_platform_collision(right_platform, true)
