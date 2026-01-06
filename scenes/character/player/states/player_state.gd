class_name PlayerState
extends FSMState

@export var dash_mana : int = 10
@export var giant_mana : int = 100
@export var heal_amount : int = 30
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
	var target_speed = dir * obj.get_movement_speed()
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
		obj.consume_jump()
		change_state(fsm.states.jump)
		return true
	return false

## Control hover: require a fresh jump press in air when no jumps left
func control_hover() -> bool:
	# Activate hover only when:
	# - Jump receives a NEW press (not held from last jump)
	# - No jumps left
	# - In the air and not on a wall
	if Input.is_action_just_pressed("jump") and obj.can_hover and not obj.can_jump() and not obj.is_on_floor():
		if not obj.is_on_wall():
			# Play hover/dash sound immediately (pitched down and quieter)
			var dash_snd = AudioStreamPlayer.new()
			dash_snd.stream = load("res://asset/sounds/dash.mp3")
			dash_snd.bus = "SFX"
			dash_snd.volume_db = -5.0
			dash_snd.pitch_scale = 0.5 # Stretched/slower effect
			obj.add_child(dash_snd)
			dash_snd.play(0.2) # Skip first 1 second
			dash_snd.finished.connect(dash_snd.queue_free)
			
			change_state(fsm.states.hover)
			return true
	return false

func control_dash() -> bool:
	if Input.is_action_just_pressed("dash") and obj.can_dash() and obj.can_use_skill(dash_mana):
		obj.take_mana(dash_mana)
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

func take_damage(damage: int = 1, hit_direction: Vector2 = Vector2.ZERO) -> void:
	#Player take damage
	obj.take_damage(damage, hit_direction)
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

func control_susanoo() -> bool:
	# Toggle Susanoo spirit on/off via dedicated state
	if Input.is_action_just_pressed("skill_susanoo"):
		# Yêu cầu phải có fire gem mới được kích hoạt skill
		if not obj.has_fire_gem:
			return true
		var existing := obj.get_node_or_null("SusanooSpirit")
		# Nếu đã có spirit, bỏ qua lần nhấn này (không làm gì cả)
		if existing != null:
			return true
		# Nếu chưa có, chuyển sang state susanoo để spawn
		if fsm.states.has("susanoo"):
			change_state(fsm.states.susanoo)
			return true
	return false

func control_water_paw() -> bool:
	# Kích hoạt Water Paw: giữ phím xuống và nhấn phím số 1 hoặc attack
	# Yêu cầu phải có water_paw_gem; tránh spawn trùng khi effect còn tồn tại
	var down_held := Input.is_action_pressed("down")
	var key1_pressed := Input.is_key_pressed(KEY_1)
	var attack_just := Input.is_action_just_pressed("attack")
	if down_held and (key1_pressed or attack_just):
		if not obj.has_water_paw_gem:
			return true
		if obj.get_node_or_null("WaterPawEffect") != null:
			return true
		# FSM lưu key theo tên node to_lower() -> "WaterPaw" => "waterpaw"
		if fsm.states.has("waterpaw"):
			change_state(fsm.states.waterpaw)
			return true
	return false

func control_room() -> bool:
	# Kích hoạt Room khi nhấn phím "room" và đã có water_room_gem
	if Input.is_action_just_pressed("room"):
		if not obj.has_water_room_gem:
			return true
		if obj.room_on_cooldown:
			return true
		# Tránh spawn trùng khi hiệu ứng còn tồn tại
		if obj.get_node_or_null("RoomSkill") != null:
			return true
		var scene := load("res://scenes/skills/room_paw/room.tscn") as PackedScene
		if scene:
			var inst := scene.instantiate()
			inst.name = "RoomSkill"
			if inst is Node2D:
				(inst as Node2D).global_position = obj.global_position
			obj.add_child(inst)
			return true
	return false
	
func control_giant_mode() ->bool:
	if Input.is_action_just_pressed("skill_giant") and obj.has_water_paw_gem and obj.can_use_giant and obj.can_use_skill(giant_mana):
		obj.take_mana(giant_mana)
		change_state(fsm.states.giant)
		return true
	return false

func control_heal_potion() -> bool:
	if Input.is_action_just_pressed("use_heal_potion") and obj.can_heal():
		obj.use_heal_potion(heal_amount) 
		return true
	return false

func control_throw_blade() -> bool:
	# Throw blade boomerang with X key
	# Requires: has_blade, blade not already flying, not in susanoo
	if Input.is_action_just_pressed("throw_blade"):
		if not obj.has_blade:
			return false
		if obj.blade_boomerang_active:
			return false
		# Không cho ném blade khi đang có Susanoo
		if obj.get_node_or_null("SusanooSpirit") != null:
			return false
		if fsm.states.has("throwblade"):
			change_state(fsm.states.throwblade)
			return true
	return false
