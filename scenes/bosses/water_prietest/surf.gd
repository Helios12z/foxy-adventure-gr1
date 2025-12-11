extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("surf")

func _update(delta: float) -> void:
	var player = obj.get_player()
	if player == null:
		change_state(fsm.states.idle)
		return

	# Remove platform restrictions - boss attacks regardless of player platform position

	var dist_x = get_horizontal_distance_to_player()
	var dy := get_vertical_diff_to_player(player)
	var abs_dy = abs(dy)

	var in_attack_height = abs_dy <= SAME_LEVEL_THRESHOLD
	var in_attack_range = dist_x <= obj.attack_range
	# Check if player is in attack range (both horizontally and vertically)
	var can_attack_now = in_attack_height and in_attack_range

	# --------- DEFEND LOGIC ---------
	if obj.should_defend():
		obj.velocity.x = 0.0
		change_state(fsm.states.defend)
		return

	# --------- NẾU ĐANG COOLDOWN TẤN CÔNG ---------
	if not obj.can_attack:
		if in_attack_height:
			var dir = sign(player.global_position.x - obj.global_position.x)
			obj.velocity.x = dir * obj.surf_speed
		else:
			if obj.move_mode == obj.MoveMode.MOVE_NONE:
				decide_move_mode_towards_player()

			var target_x: float
			match obj.move_mode:
				obj.MoveMode.MOVE_CHASE_SAME_LEVEL:
					target_x = player.global_position.x
				obj.MoveMode.MOVE_GO_EDGE_FOR_FALL, obj.MoveMode.MOVE_GO_EDGE_FOR_JUMP:
					target_x = obj.move_target_x
				_:
					target_x = player.global_position.x

			var dir = sign(target_x - obj.global_position.x)
			if abs(target_x - obj.global_position.x) <= 4.0 and obj.move_mode != obj.MoveMode.MOVE_CHASE_SAME_LEVEL:
				obj.velocity.x = 0.0
				# In phase 2, if boss is on floating platform, don't immediately fall/jump just because player is below
				if not obj.in_phase2 or not obj.is_on_floating_platform():
					if dy > 0.0:
						change_state(fsm.states.fall)
					else:
						change_state(fsm.states.jump)
			else:
				obj.velocity.x = dir * obj.surf_speed
		return

	# --------- PHASE 2 ATTACK PATTERNS (CHỈ KHI VỪA TẦM) ---------
	if can_attack_now:
		obj.velocity.x = 0.0
		obj.start_attack_cooldown()

		var attack_chance = randf()
		if attack_chance < 0.1:
			change_state(fsm.states.atk_1)
		elif attack_chance < 0.4:
			change_state(fsm.states.atk_2)
		elif attack_chance < 0.7:
			change_state(fsm.states.atk_3)
		else:
			change_state(fsm.states.atk_super)
		return

	# --------- CHƯUA VÀO WINDOW ĐÁNH → DI CHUYỂN CHUẨN BỊ JUMP/FALL ---------
	if obj.move_mode == obj.MoveMode.MOVE_NONE:
		decide_move_mode_towards_player()

	var target_x: float
	match obj.move_mode:
		obj.MoveMode.MOVE_CHASE_SAME_LEVEL:
			target_x = player.global_position.x
		obj.MoveMode.MOVE_GO_EDGE_FOR_FALL, obj.MoveMode.MOVE_GO_EDGE_FOR_JUMP:
			target_x = obj.move_target_x
		_:
			target_x = player.global_position.x

	var dir = sign(target_x - obj.global_position.x)

	# Random jump behavior - 25% chance to jump even when moving (higher in surf state)
	if randf() < 0.25:
		change_state(fsm.states.jump)
		return

	if abs(target_x - obj.global_position.x) <= 4.0 and obj.move_mode != obj.MoveMode.MOVE_CHASE_SAME_LEVEL:
		obj.velocity.x = 0.0
		# In phase 2, if boss is on floating platform, don't immediately fall/jump just because player is below
		# Let the phase 2 platform brain handle movement decisions instead
		if not obj.in_phase2 or not obj.is_on_floating_platform():
			if dy > 0.0:
				change_state(fsm.states.fall)
			else:
				change_state(fsm.states.jump)
	else:
		obj.velocity.x = dir * obj.surf_speed
