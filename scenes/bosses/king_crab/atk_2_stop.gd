extends EnemyState

func _enter() -> void:
	obj.change_animation("atk2_stop")
	print("enter atk2 stop")
	obj.velocity.x=0.0
	timer=1.25

func _update(delta: float) -> void:
	timer-=delta
	if timer<=0.0: 
		change_state(fsm.states.walk)
