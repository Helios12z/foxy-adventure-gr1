extends EnemyState

func _enter()->void:
	obj.change_animation("cast") 
	timer = 1.5
	obj.play_attack_effect(3, 1.5)
	
func _update(d: float)->void:
	if update_timer(timer):
		change_state(fsm.states.atk3_windup)
		obj.stop_attack_effect()
