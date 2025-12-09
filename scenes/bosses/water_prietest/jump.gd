# States/Jump.gd
extends WaterPrietestState

var _jump_target_marker: JumpMarker2D = null
var _jump_target_x: float = 0.0
var _jump_dir_x: int = 0
var _has_reached_peak: bool = false

const SIDE_MARGIN := 8.0           # chừa mép platform 1 ít
const DEFAULT_HALF_WIDTH := 48.0   # fallback nếu không lấy được CollisionShape
const EXTRA_JUMP_HEIGHT := 24.0    # nhảy cao hơn mặt platform một chút

func _enter() -> void:
	obj.change_animation("jump")
	_has_reached_peak = false

	var player = obj.get_player()

	# --- CASE ĐẶC BIỆT: phase 2 & boss muốn nhảy xuống ground (không dùng marker) ---
	if obj.in_phase2 and obj.force_phase2_ground_jump:
		_jump_target_marker = null
		_fallback_jump_to_player(player)
		obj.force_phase2_ground_jump = false
		return

	# --- CASE CHÍNH: dùng jump marker + nhảy lên platform từ bên trái/phải ---
	if player:
		_jump_target_marker = obj.get_best_jump_marker_to_player()

		if _jump_target_marker == null:
			_fallback_jump_to_player(player)
		else:
			_jump_to_marker_side(_jump_target_marker)
	else:
		_fallback_jump_to_player(null)


func _fallback_jump_to_player(player: Node2D) -> void:
	var target_x := obj.global_position.x

	if player:
		target_x = player.global_position.x

		var lb: Rect2 = obj.level_bounds
		if lb.size.x > 0.0:
			target_x = clamp(target_x, lb.position.x, lb.position.x + lb.size.x)

	_jump_target_x = target_x
	_perform_jump_to_position(_jump_target_x, obj.global_position.y)


func _jump_to_marker_side(marker: JumpMarker2D) -> void:
	if not marker:
		_fallback_jump_to_player(null)
		return

	var platform := marker.get_parent() as Node2D
	var target_x := marker.global_position.x
	var target_y := marker.global_position.y   # mặt trên platform

	if platform:
		var half_w := _get_platform_half_width(platform)

		# Boss đang bên trái hay phải platform?
		if obj.global_position.x < platform.global_position.x:
			# nhảy lên gần mép trái
			target_x = platform.global_position.x - (half_w - SIDE_MARGIN)
		else:
			# nhảy lên gần mép phải
			target_x = platform.global_position.x + (half_w - SIDE_MARGIN)
	else:
		# fallback: lệch sang trái/phải marker một chút
		var side_offset := 32.0
		if obj.global_position.x < marker.global_position.x:
			target_x = marker.global_position.x - side_offset
		else:
			target_x = marker.global_position.x + side_offset

	# Clamp theo level bounds
	var lb: Rect2 = obj.level_bounds
	if lb.size.x > 0.0:
		target_x = clamp(target_x, lb.position.x, lb.position.x + lb.size.x)

	_jump_target_marker = marker
	_jump_target_x = target_x
	_perform_jump_to_position(_jump_target_x, target_y)


func _get_platform_half_width(platform: Node2D) -> float:
	for child in platform.get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is RectangleShape2D:
				return shape.extents.x
	return DEFAULT_HALF_WIDTH


func _get_gravity() -> float:
	# Lấy gravity global của project
	var g = ProjectSettings.get_setting("physics/2d/default_gravity")
	if typeof(g) == TYPE_FLOAT or typeof(g) == TYPE_INT:
		return float(g)
	return 980.0


func _perform_jump_to_position(target_x: float, target_y: float) -> void:
	# --- TÍNH VẬN TỐC NHẢY DỰA VÀO VẬT LÝ ĐỂ TẠO QUỸ ĐẠO VÒNG CUNG ---

	var start_pos := obj.global_position
	var dx := target_x - start_pos.x
	var dy := target_y - start_pos.y

	# Muốn boss nhảy cao hơn mặt platform một chút
	# Trong hệ tọa độ Godot: y tăng xuống dưới, nên "cao hơn" nghĩa là giảm y
	var needed_up_height = max(0.0, start_pos.y - target_y + EXTRA_JUMP_HEIGHT)

	var g := _get_gravity()

	# Từ h = v^2 / (2g) => v = sqrt(2gh), nhưng hướng lên là âm
	var initial_vy := -sqrt(2.0 * g * needed_up_height)

	# Thời gian từ lúc nhảy tới khi boss ở ngang cao độ target_y (xấp xỉ)
	# y(t) = vy*t + 0.5*g*t^2  =>  giải t cho y(t) = dy (dy = target_y - start_y)
	# Đơn giản hơn: ước lượng thời gian dùng chiều cao, sau đó điều chỉnh vx theo dx
	var time_to_peak := -initial_vy / g
	var total_time := time_to_peak * 2.0
	total_time = clamp(total_time, 0.4, 1.2)

	var vx := dx / total_time
	var max_air_speed = obj.air_horizontal_speed
	# Clamp horizontal speed để không vượt quá tốc độ trong không khí
	if abs(vx) > max_air_speed:
		var sign_vx = sign(vx)
		vx = sign_vx * max_air_speed

	_jump_dir_x = sign(vx)
	if _jump_dir_x == 0:
		_jump_dir_x = 1

	obj.change_direction(_jump_dir_x)

	obj.velocity.x = vx
	obj.velocity.y = initial_vy


func _update(delta: float) -> void:
	if not _has_reached_peak and obj.velocity.y >= 0:
		_has_reached_peak = true

	if _has_reached_peak:
		_check_air_attack_opportunity()

	_clamp_position_to_bounds()

	# Sau khi qua đỉnh thì để Fall state xử lý tiếp
	if obj.velocity.y >= 0 and _has_reached_peak:
		change_state(fsm.states.fall)


func _check_air_attack_opportunity() -> void:
	var player = obj.get_player()
	if not player or not obj.in_phase2:
		return

	var distance = obj.global_position.distance_to(player.global_position)
	var vertical_diff = abs(obj.global_position.y - player.global_position.y)

	if distance <= 150.0 and vertical_diff <= 100.0:
		var player_dir = sign(player.global_position.x - obj.global_position.x)
		var facing_dir = 1 if not obj.animated_sprite_2d.flip_h else -1

		if player_dir == facing_dir:
			# Giảm tần suất cho đỡ spam
			if randf() < 0.3:
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
