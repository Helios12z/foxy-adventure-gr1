extends Node2D

signal complete_moving_up

@export var rect_platform: Node2D
@export var diamond_platform: Node2D

@export var rise_height: float = 200.0
@export var rise_time: float = 3.5

@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")

var _intro_done := false
var _returned := false
var _rect_start_pos: Vector2

func _ready() -> void:
	assert(rect_platform != null)
	assert(diamond_platform != null)

	_rect_start_pos = rect_platform.global_position

	diamond_platform.visible = false
	if "modulate" in diamond_platform:
		diamond_platform.modulate.a = 1.0
	_set_platform_collision(diamond_platform, false)


func start_boss_intro() -> void:
	if _intro_done:
		return
	_intro_done = true

	if camera:
		camera.camera_shake(0.4, 22)

	diamond_platform.global_position = _rect_start_pos
	diamond_platform.visible = true
	if "modulate" in diamond_platform:
		diamond_platform.modulate.a = 1.0
	_set_platform_collision(diamond_platform, true)

	if "modulate" in rect_platform:
		rect_platform.modulate.a = 1.0

	var tw := create_tween()
	tw.set_parallel(true)

	tw.tween_property(
		diamond_platform,
		"global_position:y",
		_rect_start_pos.y - rise_height,
		rise_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if "modulate" in rect_platform:
		tw.tween_property(
			rect_platform,
			"modulate:a",
			0.0,
			rise_time
		)

	tw.finished.connect(func ():
		rect_platform.visible = false
		emit_signal("complete_moving_up")
	)


func return_platform_after_boss_dead() -> void:
	if _returned:
		return
	_returned = true

	rect_platform.visible = true
	if "modulate" in rect_platform:
		rect_platform.modulate.a = 0.0
	_set_platform_collision(rect_platform, true)

	var tw := create_tween()
	tw.set_parallel(true)

	tw.tween_property(
		diamond_platform,
		"global_position:y",
		_rect_start_pos.y,
		rise_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	if "modulate" in rect_platform:
		tw.tween_property(
			rect_platform,
			"modulate:a",
			1.0,
			rise_time
		)

	tw.finished.connect(func ():
		_set_platform_collision(diamond_platform, false)
		diamond_platform.visible = false
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
