extends EnemyState

func _enter()->void:
	obj.change_animation("idle")
	timer=1.25

func _update(delta: float)->void:
	timer-=delta
	if (timer<=0):
		change_state(fsm.states.walk)
