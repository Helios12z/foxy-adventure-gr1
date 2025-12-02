extends EnemyState
class_name HassasinState

const SAME_LEVEL_THRESHOLD := 24.0  # tuỳ map mà chỉnh

# Chênh lệch theo trục Y (player - boss)
func get_vertical_diff_to_player(player: Node2D) -> float:
	return player.global_position.y - obj.global_position.y

# Tính mép gần nhất theo hướng player, dùng level_bounds của Hassasin
func get_edge_x_towards_player(player: Node2D) -> float:
	var lb: Rect2 = obj.level_bounds
	# Nếu chưa set bound thì cho chạy thẳng tới player
	if lb.size.x == 0.0:
		return player.global_position.x

	var left_edge := lb.position.x
	var right_edge := lb.position.x + lb.size.x
	var player_on_right := player.global_position.x > obj.global_position.x

	return right_edge if player_on_right else left_edge

# Logic QUYẾT ĐỊNH move_mode + move_target_x
func decide_move_mode_towards_player() -> void:
	var player = obj.get_player()
	if player == null:
		return

	var dy := get_vertical_diff_to_player(player)
	var abs_dy = abs(dy)

	if abs_dy <= SAME_LEVEL_THRESHOLD:
		# Cùng mặt phẳng
		obj.move_mode = obj.MoveMode.MOVE_CHASE_SAME_LEVEL
		obj.move_target_x = player.global_position.x
	else:
		# Khác mặt phẳng: chọn mép theo hướng player
		var edge_x := get_edge_x_towards_player(player)

		if dy > 0.0:
			# Player ở DƯỚI → chuẩn bị chạy tới mép rồi FALL
			obj.move_mode = obj.MoveMode.MOVE_GO_EDGE_FOR_FALL
		else:
			# Player ở TRÊN → chuẩn bị chạy tới mép rồi JUMP
			obj.move_mode = obj.MoveMode.MOVE_GO_EDGE_FOR_JUMP

		obj.move_target_x = edge_x
