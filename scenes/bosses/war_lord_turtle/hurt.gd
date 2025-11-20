extends EnemyState

func _enter()->void:
	obj.change_animation("hurt")
	timer=0.9
	
func _update(delta: float)->void:
	if update_timer(delta): 
		change_state(fsm.states.idle)
