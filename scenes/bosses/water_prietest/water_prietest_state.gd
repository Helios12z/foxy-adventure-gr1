extends EnemyState
class_name WaterPrietestState

const SAME_LEVEL_THRESHOLD := 24.0  # tuỳ map mà chỉnh

# Chênh lệch theo trục Y (player - boss)
func get_vertical_diff_to_player(player: Node2D) -> float:
	return player.global_position.y - obj.global_position.y

func get_horizontal_distance_to_player() -> float:
	var player = obj.get_player()
	if player == null:
		return INF
	return abs(player.global_position.x - obj.global_position.x)

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

func do_atk1() -> void:
	var sprite = obj.animated_sprite_2d
	if sprite == null:
		return

	if not sprite.frame_changed.is_connected(_on_atk1_frame_changed):
		sprite.frame_changed.connect(_on_atk1_frame_changed)

	if not sprite.animation_finished.is_connected(_on_atk1_anim_finished):
		sprite.animation_finished.connect(_on_atk1_anim_finished)


func _on_atk1_frame_changed() -> void:
	var sprite = obj.animated_sprite_2d
	if sprite == null:
		return

	# Nếu không còn ở animation atk_1 thì tắt hitbox và thôi
	if sprite.animation != "atk_1":
		if obj.atk1_collision_shape_2d:
			obj.atk1_collision_shape_2d.disabled = true
		return

	var current_frame = sprite.frame
	var active = (current_frame == 2 or current_frame == 3)

	if obj.atk1_collision_shape_2d:
		obj.atk1_collision_shape_2d.disabled = not active


func _on_atk1_anim_finished() -> void:
	var sprite = obj.animated_sprite_2d
	if sprite == null:
		return

	# Chỉ xử lý nếu vừa xong animation atk_1
	if sprite.animation != "atk_1":
		return

	# Tắt hitbox
	if obj.atk1_collision_shape_2d:
		obj.atk1_collision_shape_2d.disabled = true

	# Ngắt signal để tránh bị call nhiều lần
	if sprite.frame_changed.is_connected(_on_atk1_frame_changed):
		sprite.frame_changed.disconnect(_on_atk1_frame_changed)

	if sprite.animation_finished.is_connected(_on_atk1_anim_finished):
		sprite.animation_finished.disconnect(_on_atk1_anim_finished)

	# Animation atk_1 xong -> về idle (hoặc state khác tuỳ bạn)
	if obj.fsm:
		obj.fsm.change_state(obj.fsm.states.idle)
