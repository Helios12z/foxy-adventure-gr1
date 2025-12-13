extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("surf")

func _update(delta: float) -> void:
	var player = obj.get_player()
	if player == null:
		change_state(fsm.states.idle)
		return

	var dist_x = get_horizontal_distance_to_player()
	var dy := get_vertical_diff_to_player(player)
	var abs_dy = abs(dy)

	var in_attack_height = abs_dy <= SAME_LEVEL_THRESHOLD
	var in_attack_range = dist_x <= obj.attack_range
	var can_attack_now = in_attack_height and in_attack_range

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
				_:
					target_x = player.global_position.x

			var dir = sign(target_x - obj.global_position.x)
			if abs(target_x - obj.global_position.x) <= 4.0:
				obj.velocity.x = 0.0
				change_state(fsm.states.jumpstate)
			else:
				obj.velocity.x = dir * obj.surf_speed
		return

	if can_attack_now:
		obj.velocity.x = 0.0
		obj.start_attack_cooldown()

		var attack_chance = randf()
		if attack_chance < 0.15:
			change_state(fsm.states.atk_1)
		elif attack_chance < 0.35:
			change_state(fsm.states.atk_2)
		elif attack_chance < 0.6:
			change_state(fsm.states.atk_3)
		else:
			change_state(fsm.states.atk_super)
		return

	if obj.move_mode == obj.MoveMode.MOVE_NONE:
		decide_move_mode_towards_player()

	var target_x: float
	match obj.move_mode:
		obj.MoveMode.MOVE_CHASE_SAME_LEVEL:
			target_x = player.global_position.x
		_:
			target_x = player.global_position.x

	var dir = sign(target_x - obj.global_position.x)

	if randf() < 0.25 and not obj.is_on_floating_platform():
		change_state(fsm.states.jumpstate)
		return

	if abs(target_x - obj.global_position.x) <= 4.0:
		obj.velocity.x = 0.0
		if not obj.is_on_floating_platform(): change_state(fsm.states.jumpstate)
	else:
		obj.velocity.x = dir * obj.surf_speed
