extends WarlordTurtleState

func _enter() -> void:
	timer = 2.25
	obj.change_animation("stun")

func _update(delta: float) -> void:
	if update_timer(delta):
		fsm.change_state(fsm.states.idle)
