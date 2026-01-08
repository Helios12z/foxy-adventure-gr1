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
var _player_base_gravity: float = 0.0
var _player_rise_tween: Tween = null
var _player_offset_above_platform: float = 80.0  # Distance player stays above platform
var _player_float_tween: Tween = null
var _player_float_base_y: float = 0.0

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

	var player := _get_player()
	if player:
		# Set player to anti-gravity state
		_start_player_float(player)

		# Disable platform collision with player so platform doesn't push player
		_set_platform_collision_with_player(floating_platform, false)

		# Disable player movement during transition
		player.set_can_move(false)

		# Calculate player's target Y: player_current_y - rise_height - 80
		# This ensures player ends up 80px above the platform's max height
		var lift_distance := rise_height + 80.0
		var player_target_y := player.global_position.y - lift_distance

		# Step 1: Lift player up (0.5 seconds)
		var lift_tween := create_tween()
		lift_tween.tween_property(
			player,
			"global_position:y",
			player_target_y,
			0.5
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# Store the base Y position for floating effect
		_player_float_base_y = player_target_y

		# Step 2: After player lift complete, start floating bob effect
		lift_tween.finished.connect(func():
			# Start the gentle bobbing effect
			_start_player_float_bob(player)

			# Wait 0.75s then start platform rise
			await get_tree().create_timer(0.75).timeout

			# Step 3: Platform rises (player stays at same height in anti-gravity)
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
				# Step 4: Platform rise complete - restore everything
				_stop_player_float_bob()
				_restore_player_gravity(player)
				_set_platform_collision_with_player(floating_platform, true)
				player.set_can_move(true)
			)
		)
	else:
		# No player found, just rise the platform
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

func _get_player() -> Player:
	return get_tree().get_first_node_in_group("Player") as Player

func _set_platform_collision_with_player(platform: TileMapLayer, enabled: bool) -> void:
	# Disable/enable collision between platform and player (layer 2)
	if platform == null:
		return

	# For TileMapLayer, iterate through the physics bodies it creates and set their collision layers
	for child in platform.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			# Get the parent StaticBody2D that owns this shape
			var body = child.get_parent()
			if body and body is StaticBody2D:
				if enabled:
					body.set_collision_mask_value(2, true)
				else:
					body.set_collision_mask_value(2, false)

func _start_player_float(player: Player) -> void:
	# Cache player's base gravity
	_player_base_gravity = player._base_gravity

	# Set both gravity and base_gravity to zero for anti-gravity effect
	# This prevents _apply_safe_zone_mods() from overriding it
	player.gravity = 0
	player._base_gravity = 0

	# Stop any downward velocity
	if player.velocity.y > 0:
		player.velocity.y = 0

func _restore_player_gravity(player: Player) -> void:
	# Restore both gravity and base_gravity to original value
	player.gravity = _player_base_gravity
	player._base_gravity = _player_base_gravity

func _start_player_float_bob(player: Player) -> void:
	# Stop any existing float tween
	if is_instance_valid(_player_float_tween):
		_player_float_tween.kill()

	# Create a looping up-down bobbing effect
	_player_float_tween = create_tween()
	_player_float_tween.set_loops()
	_player_float_tween.set_parallel(false)

	var bob_amount := 5.0  # Bob up and down by 5 pixels
	var bob_duration := 1.0  # Complete one up-down cycle in 1 second

	# Bob up
	_player_float_tween.tween_property(
		player,
		"global_position:y",
		_player_float_base_y - bob_amount,
		bob_duration * 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Bob down
	_player_float_tween.tween_property(
		player,
		"global_position:y",
		_player_float_base_y + bob_amount,
		bob_duration * 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_player_float_bob() -> void:
	# Stop the floating bob effect
	if is_instance_valid(_player_float_tween):
		_player_float_tween.kill()
		_player_float_tween = null

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
