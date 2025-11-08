extends EnemyState

func _enter()->void:
	obj.change_animation("cast")
	timer = obj.atk3_cast_time
	obj.play_attack_effect(3, timer)
	obj._begin_fly_mode()
	obj._proximity_enabled = false
	obj._atk3_liftoff_x = obj.global_position.x

func _update(d: float)->void:
	if update_timer(d):
		obj._disable_attack_effect()
		change_state(fsm.states.atk3_windup)
