extends WarlordTurtleState

var _has_fired: bool = false

func _enter() -> void:
	_has_fired = false
	obj.change_animation("strafe")

func _update(_delta: float) -> void:
	if not _has_fired:
		_has_fired = true
		_beam_attack()
		return

	if not _are_beams_active():
		change_state(fsm.states.strafe_stop)
