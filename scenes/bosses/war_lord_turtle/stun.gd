extends WarlordTurtleState

func _enter() -> void:
	timer = obj.stun_time
	obj.change_animation("stun")

func _update(delta: float) -> void:
	if update_timer(delta):
		fsm.change_state(fsm.states.idle)
