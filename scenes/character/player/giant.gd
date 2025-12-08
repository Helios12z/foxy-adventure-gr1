extends PlayerState


func _enter() -> void:
	obj.activate_giant_form()

func _update(_delta: float) -> void:
	control_jump()
	control_moving(_delta)
	control_attack()

	if not obj.is_on_floor():
		change_state(fsm.states.fall)
