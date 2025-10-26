extends PlayerState

func _enter() -> void:
	#Change animation to fall
	obj.change_animation("fall")


func _update(_delta: float) -> void:
	#Control dash
	if control_dash():
		return
	#Control moving
	control_jump()
	var is_moving: bool = control_moving()
	#If on floor change to idle if not moving and not jumping
	if obj.is_on_floor():
		obj.reset_jump_count()
	if obj.is_on_floor() and not is_moving:
		change_state(fsm.states.idle)
	

	
