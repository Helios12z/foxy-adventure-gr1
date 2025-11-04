extends PlayerState

func _enter() -> void:
	#Change animation to fall
	obj.change_animation("fall")

func _update(_delta: float) -> void:
	#Control dash
	if control_dash():
		return
	#Control hover (giữ jump trên không, hết lượt nhảy)
	if control_hover():
		return
	#Control moving
	control_jump()
	control_attack()
	var is_moving: bool = control_moving(_delta)

	# Check for wall climbing
	if obj.can_wall_slide():
		var input_dir = Input.get_axis("left", "right")
		# Only climb if moving towards the wall
		if (obj.is_on_left_wall() and input_dir < 0) or (obj.is_on_right_wall() and input_dir > 0):
			change_state(fsm.states.climb)
			return

	if obj.is_on_floor() and not is_moving:
		change_state(fsm.states.idle)
	

	
