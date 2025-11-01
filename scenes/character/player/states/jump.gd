extends PlayerState

var wall_jump_timer: float = 0.0
var wall_jump_duration: float = 0.3  # 0.3 seconds to preserve wall jump momentum

func _enter() -> void:
	#Change animation to jump
	obj.change_animation("jump")
	
	# Check if this is a wall jump by looking at horizontal velocity
	if abs(obj.velocity.x) > obj.movement_speed:
		wall_jump_timer = wall_jump_duration

func _update(_delta: float):
	#Control dash
	if control_dash():
		return
	#Control moving
	control_jump()
	
	# Update wall jump timer
	if wall_jump_timer > 0:
		wall_jump_timer -= _delta
	
	# Only control moving if wall jump timer has expired
	if wall_jump_timer <= 0:
		#Control moving
		control_moving()
		
	# Check for wall climbing
	if obj.can_wall_slide():
		var input_dir = Input.get_axis("left", "right")
		# Only climb if moving towards the wall
		if (obj.is_on_left_wall()) or (obj.is_on_right_wall()):
			change_state(fsm.states.climb)
			return
			
	#If velocity.y is greater than 0 change to fall
	if obj.velocity.y > 0:
		change_state(fsm.states.fall)
	
