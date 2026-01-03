extends EnemyState

## Return Home state for FlyEye
## Flies back to original spawn position before resuming patrol

@export var return_speed: float = 80.0
@export var return_vertical_speed: float = 100.0
@export var home_threshold: float = 10.0  # Distance to consider "arrived"


func _enter() -> void:
	obj.change_animation("walk")
	print("[ReturnHome] Flying back to home position")
	print("[ReturnHome] Current pos: ", obj.global_position)
	print("[ReturnHome] Home pos: ", obj.get("home_position"))


func _update(delta: float) -> void:
	# Check if player detected (interrupt return home)
	if obj.can_detect_player():
		print("[ReturnHome] Player detected, interrupting")
		change_state(fsm.states.chase)
		return

	# Get home position
	var home_pos = obj.get("home_position")
	if not home_pos or home_pos == null:
		print("[ReturnHome] ERROR: No home position!")
		change_state(fsm.states.walk)
		return

	# Calculate distance to home
	var y_diff = home_pos.y - obj.global_position.y
	var x_diff = home_pos.x - obj.global_position.x
	var distance = obj.global_position.distance_to(home_pos)

	print("[ReturnHome] Distance to home: ", distance, " Y diff: ", y_diff, " X diff: ", x_diff)

	# Check if arrived at home
	if distance < home_threshold:
		print("[ReturnHome] Arrived at home position")
		change_state(fsm.states.walk)
		return

	# Move vertically toward home Y position
	if abs(y_diff) < home_threshold:
		# On same level, stop vertical movement
		obj.velocity.y = 0
	elif y_diff > 0:
		# Home is below
		obj.velocity.y = return_vertical_speed
	else:
		# Home is above
		obj.velocity.y = -return_vertical_speed

	# Move horizontally toward home X position
	if abs(x_diff) < home_threshold:
		# At home X, stop horizontal movement
		obj.velocity.x = 0
	elif x_diff > 0:
		# Home is to the right
		if obj.direction != 1:
			obj.change_direction(1)  # Use change_direction instead
		obj.velocity.x = return_speed
	else:
		# Home is to the left
		if obj.direction != -1:
			obj.change_direction(-1)  # Use change_direction instead
		obj.velocity.x = -return_speed

	# Check for wall ahead
	if obj.has_method("is_wall_ahead") and obj.is_wall_ahead():
		# If there's a wall, stop horizontal movement but continue vertical
		obj.velocity.x = 0

	# Move
	obj.move_and_slide()


func _exit() -> void:
	print("[ReturnHome] Exited return home state")
