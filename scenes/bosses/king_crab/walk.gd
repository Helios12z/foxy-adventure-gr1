extends EnemyState

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta: float) -> void:
	var ready = obj.control_move()

	if ready:
		var can1 = obj.can_attack1()
		var can2 = obj.can_attack2()

		if obj.next_attack_is_claw and can1:
			change_state(fsm.states.atk1_windup); return
		if (not obj.next_attack_is_claw) and can2:
			change_state(fsm.states.atk2_roll); return

		if can1: change_state(fsm.states.atk1_windup); return
		if can2: change_state(fsm.states.atk2_roll); return
