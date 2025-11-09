extends EnemyState

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta: float) -> void:
	if obj.in_phase2 and obj._chain_after_basic:
		obj._chain_after_basic = false
		if randf() < obj.chain_after_basic_prob:
			change_state(fsm.states.summon_minion)
		else:
			change_state(fsm.states.atk3_cast)
		return 

	var ready = obj.control_move()
	if not ready: return
	if obj.found_player == null: return

	var dx = obj.found_player.global_position.x - obj.global_position.x
	var desired: int 
	if dx >= 0: desired = 1
	else: desired = -1 
	if desired != obj.direction:
		obj.change_direction(desired)
	obj.queued_bullet_dir_x = float(desired)

	var can1 = obj.can_attack1()
	var can2 = obj.can_attack2()

	if obj.next_attack_is_claw and can1:
		change_state(fsm.states.atk1_windup)
		return
	if (not obj.next_attack_is_claw) and can2:
		change_state(fsm.states.atk2_windup)
		return
