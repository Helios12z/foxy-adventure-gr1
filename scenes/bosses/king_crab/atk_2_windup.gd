extends EnemyState

func _enter() -> void:
	obj.change_animation("atk2_windup")
	timer = 0.75
	obj.play_attack_effect(2, timer)
	obj.queued_roll_dir_x=obj.direction

func _update(d: float) -> void:
	if update_timer(d): 
		obj._disable_attack_effect()
		change_state(fsm.states.atk2_roll)
