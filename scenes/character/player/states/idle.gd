extends PlayerState

## Idle state for player character

func _enter() -> void:
	obj.change_animation("idle")
	if fsm.previous_state == fsm.states.hurt:
		obj.start_invulnerability()

func _update(_delta: float) -> void:
	#Control dash
	if control_dash():
		return
	#Control jump
	control_jump()
	#Control moving
	control_moving(_delta)
	#If not on floor change to fall
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
