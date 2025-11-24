extends WarlordTurtleState

func _enter()->void:
	obj.change_animation("cast")
	timer = 1.75
	
func _update(d: float) -> void:
	if update_timer(d):
		change_state(fsm.states.atk_3)
