class_name PlayerState
extends FSMState

#Control moving and changing state to run
#Return true if moving
#Add friction and acceleration effects
func control_moving(delta) -> bool:
	var dir: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var is_moving: bool = abs(dir) > 0.1
	
	# Chỉ cập nhật hướng khi có input; tránh đặt direction = 0 khi idle
	if is_moving:
		dir = sign(dir)
		obj.change_direction(dir)
	else:
		# Giữ nguyên hướng hiện tại để các state (ví dụ dash) dùng được
		dir = obj.direction
	var target_speed = dir * obj. movement_speed
	var current_deccel = obj.deccel if obj.is_on_floor() else obj.air_deccel
	
	if is_moving:
		obj.velocity.x = target_speed
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

# Detect double-tap left/right to enter Run state
func control_run() -> bool:
	var dir_run: int = obj.check_run_double_tap()
	if dir_run != 0 and obj.is_on_floor():
		obj.change_direction(dir_run)
		obj.velocity.x = obj.get_run_speed() * dir_run
		change_state(fsm.states.run)
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
		
func control_attack() -> bool:
	if obj.can_attack():
		if Input.is_action_just_pressed("attack"):
			change_state(fsm.states.attack)
			return true
		#if Input.is_action_just_pressed("fly_blade"):
			#change_state(fsm.states.flyblade)
			#return true
		#if Input.is_action_just_pressed("throw_blade"):
			#change_state(fsm.states.throwblade)
			#return true
	return false
