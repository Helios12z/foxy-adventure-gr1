extends PlayerState

func _enter() -> void:
	#Change animation to run
	obj.change_animation("walk")
	pass

func _update(_delta: float):
	# Detect run double-tap while walking
	if control_run():
		return
	#Control dash
	if control_dash():
		return
	#Control jump
	if control_jump():
		return
	#Control moving and if not moving change to idle
	if not control_moving(_delta):
		change_state(fsm.states.idle)
	#If not on floor change to fall
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
	pass
