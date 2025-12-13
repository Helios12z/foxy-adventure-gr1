extends WaterPrietestState

@export var walk_speed: float = 60.0  

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

	var in_attack_height = abs_dy <= SAME_LEVEL_THRESHOLD
	var in_attack_range = dist_x <= obj.attack_range
	var can_attack_now = in_attack_height and in_attack_range

	if not obj.can_attack:
		if in_attack_height:
			var dir = sign(player.global_position.x - obj.global_position.x)
			obj.velocity.x = dir * walk_speed
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
				if dy > 0.0:
					change_state(fsm.states.fall)
				else:
					change_state(fsm.states.jump)
			else:
				obj.velocity.x = dir * walk_speed
		return

	if can_attack_now:
		obj.velocity.x = 0.0
		obj.start_attack_cooldown()

		var attack_choice = randi() % 2
		if attack_choice == 0:
			change_state(fsm.states.atk_1)
		else:
			change_state(fsm.states.atk_2)
		return

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
		if dy > 0.0:
			change_state(fsm.states.fall)
		else:
			change_state(fsm.states.jump)
	else:
		obj.velocity.x = dir * walk_speed
