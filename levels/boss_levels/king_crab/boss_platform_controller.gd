extends Node2D

signal complete_moving_up

@export var rect_platform: Node2D
@export var diamond_platform: Node2D
@onready var spear_platform: TileMapLayer = $Spear
@onready var left_platform: TileMapLayer = $LeftPlatform
@onready var right_platform: TileMapLayer = $RightPlatform

@export var rise_height: float = 200.0
@export var rise_time: float = 3.5

@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")

@onready var craking: AudioStreamPlayer2D = $"../../Sound/Craking"

var _intro_done := false
var _returned := false
var _rect_start_pos: Vector2

func _ready() -> void:
	assert(rect_platform != null)
	assert(diamond_platform != null)

	_rect_start_pos = rect_platform.global_position

	if "modulate" in diamond_platform:
		diamond_platform.modulate.a = 1.0
	
	spear_platform.visible = false 
	_set_platform_collision(spear_platform, false)
	
	right_platform.visible = false 
	_set_platform_collision(right_platform, false)

func start_boss_intro() -> void:
	if _intro_done:
		return
	_intro_done = true

	if camera:
		camera.camera_shake(0.4, 24)
	craking.play(2.0)
	
	left_platform.visible = false 
	_set_platform_collision(left_platform, false)

	diamond_platform.global_position = _rect_start_pos
	
	spear_platform.visible = true
	_set_platform_collision(spear_platform, true)
	
	if "modulate" in diamond_platform:
		diamond_platform.modulate.a = 1.0
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

	tw.finished.connect(func ():
		emit_signal("complete_moving_up")
		craking.stop()
	)

func return_platform_after_boss_dead() -> void:
	if _returned:
		return
	_returned = true
	
	if camera:
		camera.camera_shake(0.4, 24)
	craking.play(2.0)

	if "modulate" in rect_platform:
		rect_platform.modulate.a = 0.0

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
		craking.stop()
		spear_platform.visible = false
		_set_platform_collision(spear_platform, false)
		right_platform.visible = true 
		_set_platform_collision(right_platform, true)
		left_platform.visible = true
		_set_platform_collision(left_platform, true)
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
