class_name Climb
extends PlayerState

## State for wall climbing and sliding

func _enter() -> void:
	obj.change_animation("climb")

func _update(delta: float) -> void:
	
	# Control wall jumping (specific to climb state) - check this first
	if control_wall_jump():
		return  # Exit early if wall jump was performed
	
	# Control horizontal movement
	control_moving(delta)
	
	if obj.is_on_left_wall():
		obj.velocity.x = -50  # Ép vào tường trái
	elif obj.is_on_right_wall():
		obj.velocity.x = 50   # Ép vào tường phải
	
	# Wall sliding logic
	if obj.can_wall_slide():
		# Giảm tốc trượt 50% nếu đang giữ hướng về phía tường
		var input_dir := Input.get_axis("left", "right")
		var pressing_into_wall := (obj.is_on_left_wall() and input_dir < 0) or (obj.is_on_right_wall() and input_dir > 0)
		if pressing_into_wall:
			obj.velocity.y = min(obj.velocity.y, obj.wall_slide_speed * 0.5)
		else:
			obj.wall_slide(delta)
	
	# Transition conditions
	# If player is on floor, go to idle or run
	if obj.is_on_floor():
		# Reset jump count when landing from wall slide/climb
		obj.reset_jump_count()
		if control_moving(delta):
			change_state(fsm.states.walk)
		else:
			change_state(fsm.states.idle)
		return
	
	# If no longer touching wall, fall
	if not obj.is_on_wall():
		change_state(fsm.states.fall)
		return
	
	# If moving away from wall, fall
	var input_dir = Input.get_axis("left", "right")
	if obj.is_on_left_wall() and input_dir > 0:
		change_state(fsm.states.fall)
	elif obj.is_on_right_wall() and input_dir < 0:
		change_state(fsm.states.fall)

# Control wall jumping - specific logic for jumping while wall sliding
func control_wall_jump() -> bool:
	if Input.is_action_just_pressed("jump"):
		# Wall jump logic - only when touching wall and not on floor
		if obj.is_on_wall() and not obj.is_on_floor():
			# Apply vertical jump force
			obj.velocity.y = -obj.jump_speed
			
			# Apply horizontal push force away from wall
			var wall_jump_force = obj.movement_speed  # Stronger horizontal force for wall jump
			
			if obj.is_on_left_wall():
				obj.velocity.x = wall_jump_force  # Push right
				obj.change_direction(1)
			elif obj.is_on_right_wall():
				obj.velocity.x = -wall_jump_force  # Push left
				obj.change_direction(-1)
			
		# Reset remaining jumps to allow a later double jump
			obj.reset_jump_count()          # sets max_jump_count = 2
			obj.max_jump_count = 1          # wall jump consumes 1, leave 1 for double jump
			
			# Transition to jump state
			change_state(fsm.states.jump)
			return true
	return false
