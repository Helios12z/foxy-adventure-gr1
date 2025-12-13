extends WaterPrietestState

var _jump_target_marker: JumpMarker2D = null
var _jump_target_x: float = 0.0
var _jump_dir_x: int = 0
var _has_reached_peak: bool = false

const EXTRA_JUMP_HEIGHT := 24.0  # nhảy cao hơn mặt platform một chút

func _enter() -> void:
	obj.change_animation("jump")
	_has_reached_peak = false

	# Play jump sound
	if obj.jump_sound:
		obj.jump_sound.play()

	var player = obj.get_player()

	# Case đặc biệt: Phase 2 bắt buộc nhảy xuống ground (flag từ phase 2 brain)
	if obj.in_phase2 and obj.force_phase2_ground_jump:
		_jump_target_marker = null
		_fallback_jump_to_player(player)
		obj.force_phase2_ground_jump = false
		return

	# ---------- JUMP BẰNG GRAPH JUMP_MARKER ----------
	var from_marker: JumpMarker2D = obj.current_jump_marker
	if from_marker == null:
		from_marker = obj.get_nearest_jump_marker()

	if player and not obj.jump_markers.is_empty():
		# Marker đại diện platform player đang đứng
		var player_marker = obj.get_nearest_jump_marker_to_position(player.global_position)
		var first_step: JumpMarker2D = null

		if from_marker and player_marker:
			# Đường đi (có thể qua 0 hoặc 1 intermediate marker tuỳ get_jump_path_to_target)
			var path := from_marker.get_jump_path_to_target(player_marker)
			if path.size() > 0:
				first_step = path[0]
			else:
				first_step = player_marker
		elif player_marker:
			first_step = player_marker

		if first_step:
			_jump_target_marker = first_step
			_jump_target_x = first_step.global_position.x
			_perform_jump_to_position(first_step.global_position)
			return

	# ---------- FALLBACK: không có marker / graph ----------
	_jump_target_marker = null
	_fallback_jump_to_player(player)


func _fallback_jump_to_player(player: Node2D) -> void:
	var target_pos := obj.global_position

	if player:
		target_pos = player.global_position

		# Clamp trong room cho chắc
		var lb: Rect2 = obj.level_bounds
		if lb.size.x > 0.0:
			target_pos.x = clamp(target_pos.x, lb.position.x, lb.position.x + lb.size.x)

	_jump_target_x = target_pos.x
	_perform_jump_to_position(target_pos)


func _get_gravity() -> float:
	var g = ProjectSettings.get_setting("physics/2d/default_gravity")
	if typeof(g) == TYPE_FLOAT or typeof(g) == TYPE_INT:
		return float(g)
	return 980.0


func _perform_jump_to_position(target_pos: Vector2) -> void:
	var start_pos := obj.global_position
	var dx := target_pos.x - start_pos.x
	var dy := target_pos.y - start_pos.y

	var g := _get_gravity()

	# Chiều cao cần leo thêm (Godot y tăng xuống, nên "cao hơn" là y nhỏ hơn)
	var needed_up_height = max(0.0, start_pos.y - target_pos.y + EXTRA_JUMP_HEIGHT)

	# v^2 = 2gh -> v = sqrt(2gh), hướng lên (âm)
	var initial_vy := -sqrt(2.0 * g * needed_up_height)

	var time_to_peak := -initial_vy / g
	var total_time := time_to_peak * 2.0
	total_time = clamp(total_time, 0.35, 1.2)

	var vx := dx / total_time
	var max_air_speed = obj.air_horizontal_speed
	if abs(vx) > max_air_speed:
		vx = sign(vx) * max_air_speed

	_jump_dir_x = sign(vx)
	if _jump_dir_x == 0:
		if dx >= 0.0: _jump_dir_x = 1
		else: _jump_dir_x = -1

	obj.change_direction(_jump_dir_x)
	obj.velocity.x = vx
	obj.velocity.y = initial_vy


func _update(delta: float) -> void:
	if not _has_reached_peak and obj.velocity.y >= 0.0:
		_has_reached_peak = true

	if _has_reached_peak:
		_check_air_attack_opportunity()

	_clamp_position_to_bounds()

	if obj.velocity.y >= 0.0 and _has_reached_peak:
		change_state(fsm.states.fallstate)


func _check_air_attack_opportunity() -> void:
	var player = obj.get_player()
	if not player or not obj.in_phase2:
		return

	var distance = obj.global_position.distance_to(player.global_position)
	var vertical_diff = abs(obj.global_position.y - player.global_position.y)

	if distance <= 150.0 and vertical_diff <= 100.0:
		var player_dir = sign(player.global_position.x - obj.global_position.x)
		var facing_dir = 1 if not obj.animated_sprite_2d.flip_h else -1

		if player_dir == facing_dir and randf() < 0.3:
			change_state(fsm.states.atk_air)


func _clamp_position_to_bounds() -> void:
	var lb: Rect2 = obj.level_bounds
	if lb.size.x > 0.0:
		var pos := obj.global_position
		pos.x = clamp(pos.x, lb.position.x, lb.position.x + lb.size.x)
		obj.global_position = pos

	if obj.is_on_ceiling():
		# Nếu đụng trần, đẩy boss xuống chút để không bị kẹt
		obj.global_position.y += 2.0
