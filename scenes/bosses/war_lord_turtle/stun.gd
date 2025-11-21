extends WarlordTurtleState

func _enter() -> void:
	timer = 3.0
	obj.change_animation("stun")

func _update(delta: float) -> void:
	if update_timer(delta):
		fsm.change_state(fsm.states.idle)
