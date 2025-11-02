class_name PlayerState
extends FSMState

#Control moving and changing state to run
#Return true if moving
#Add friction and acceleration effects
func control_moving(delta) -> bool:
	var dir: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var is_moving: bool = abs(dir) > 0.1
	
	dir = sign(dir)
	obj.change_direction(dir) 
	var target_speed = dir * obj. movement_speed
	var current_accel = obj.accel if obj.is_on_floor() else obj.air_accel
	var current_deccel = obj.deccel if obj.is_on_floor() else obj.air_deccel
	
	if is_moving:
		obj.velocity.x = move_toward(obj.velocity.x, target_speed, current_accel * delta)
		if obj.is_on_floor():
			change_state(fsm.states.walk)
		return true
	else:
		obj.velocity.x = move_toward(obj.velocity.x, 0, current_deccel * delta)
		if obj.is_on_floor() and obj.velocity.x == 0:
			change_state(fsm.states.idle)
	return false

#Control jumping
#Return true if jumping
func control_jump() -> bool:
	#If jump is pressed change to jump state and return true
	if Input.is_action_just_pressed("jump") and obj.can_jump():
		obj.jump()
		obj.max_jump_count -= 1
		change_state(fsm.states.jump)
		return true
	return false

func control_dash() -> bool:
	if Input.is_action_just_pressed("dash"):
		change_state(fsm.states.dash)
		return true
	return false

func take_damage(damage: int = 1) -> void:
	#Player take damage
	obj.take_damage(damage)
	#Player die if health is 0 and change to dead state
	#Player hurt if health is not 0 and change to hurt state
	if obj.health <= 0:
		change_state(fsm.states.dead)
	else:
		change_state(fsm.states.hurt)
