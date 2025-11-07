extends EnemyState

func _enter()->void:
	obj.change_animation("hurt")
	timer=0.5
	
func _update(delta: float)->void:
	timer-=delta
	if (timer<=0):
		change_state(fsm.states.idle)
