extends KingCrabState

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta: float) -> void:
	if obj.in_phase2 and obj._chain_after_basic:
		obj._chain_after_basic = false
		var random_value = randf()
		if random_value < 0.4:
			change_state(fsm.states.atk4_windup)
		elif random_value < 0.7:
			change_state(fsm.states.summon_minion)
		else:
			change_state(fsm.states.atk3_cast)
		return 

	var ready = control_move()
	if not ready: return

	var dx = obj._get_player().global_position.x - obj.global_position.x
	var desired: int 
	if dx >= 0: desired = 1
	else: desired = -1 
	if desired != obj.direction:
		obj.change_direction(desired)
	obj.queued_bullet_dir_x = float(desired)

	var can1 = can_attack1()
	var can2 = can_attack2()

	if obj.next_attack_is_claw and can1:
		change_state(fsm.states.atk1_windup)
		return
	if (not obj.next_attack_is_claw) and can2:
		change_state(fsm.states.atk2_windup)
		return
