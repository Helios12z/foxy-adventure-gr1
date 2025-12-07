extends WaterPrietestState

@export var walk_speed: float = 60.0  # tuỳ bạn chỉnh, hoặc dùng obj.movement_speed

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta: float) -> void:
	var player = obj.get_player()
	if player == null:
		change_state(fsm.states.idle)
		return

	var dist_x = get_horizontal_distance_to_player()
	var dy := get_vertical_diff_to_player(player)
	var abs_dy = abs(dy)

	# --------- DEFEND LOGIC ---------
	if obj.should_defend():
		obj.velocity.x = 0.0
		change_state(fsm.states.defend)
		return

	# --------- PHASE-SPECIFIC ATTACK PATTERNS ---------
	if abs_dy <= SAME_LEVEL_THRESHOLD:
		# Phase 1: Only use atk1 and atk2
		if not obj.in_phase2:
			# Nếu đã vào tầm atk2 -> dừng & đánh
			if dist_x <= obj.atk2_range:
				obj.velocity.x = 0.0
				change_state(fsm.states.atk_2)
				return

			# Nếu đã vào tầm atk1 -> dừng & đánh
			if dist_x <= obj.atk1_range:
				obj.velocity.x = 0.0
				change_state(fsm.states.atk_1)
				return
		# Phase 2: Can use atk1, atk2, atk3, and atk_super
		else:
			# Random chance for super attack in phase 2
			if dist_x <= obj.atk2_range:
				var super_chance = randf()
				if super_chance < 0.3:  # 30% chance for super attack
					obj.velocity.x = 0.0
					change_state(fsm.states.atk_super)
					return

			# Nếu đã vào tầm atk3 -> dừng & đánh
			if dist_x <= obj.atk3_range:
				obj.velocity.x = 0.0
				change_state(fsm.states.atk_3)
				return

			# Nếu đã vào tầm atk2 -> dừng & đánh
			if dist_x <= obj.atk2_range:
				obj.velocity.x = 0.0
				change_state(fsm.states.atk_2)
				return

			# Nếu đã vào tầm atk1 -> dừng & đánh
			if dist_x <= obj.atk1_range:
				obj.velocity.x = 0.0
				change_state(fsm.states.atk_1)
				return

	# Nếu chênh cao độ nhiều → KHÔNG tấn công, chỉ di chuyển chuẩn bị jump/fall
	# ----------------------------------------------------

	# Đảm bảo đã có move_mode + move_target_x hợp lý
	if obj.move_mode == obj.MoveMode.MOVE_NONE:
		decide_move_mode_towards_player()

	var target_x: float

	match obj.move_mode:
		obj.MoveMode.MOVE_CHASE_SAME_LEVEL:
			# Player gần cùng mặt phẳng nhưng chưa vào range → đuổi thẳng tới player
			target_x = player.global_position.x
		obj.MoveMode.MOVE_GO_EDGE_FOR_FALL, obj.MoveMode.MOVE_GO_EDGE_FOR_JUMP:
			# Player cao/thấp hơn → chạy tới mép phù hợp để chuẩn bị fall/jump
			target_x = obj.move_target_x
		_:
			# fallback: đuổi theo player
			target_x = player.global_position.x

	var dir = sign(target_x - obj.global_position.x)

	# Nếu đã gần tới target_x (mép) thì dừng lại, chỗ này sau này bạn có thể
	# đổi sang state jump/fall riêng.
	if abs(target_x - obj.global_position.x) <= 4.0 and obj.move_mode != obj.MoveMode.MOVE_CHASE_SAME_LEVEL:
		obj.velocity.x = 0.0
		if dy > 0.0:
			change_state(fsm.states.fall)
		else:
			change_state(fsm.states.jump)
	else:
		obj.velocity.x = dir * walk_speed
