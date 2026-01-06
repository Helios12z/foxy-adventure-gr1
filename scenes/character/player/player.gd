class_name Player
extends BaseCharacter

## Player character class that handles movement, combat, and state management
signal hp_changed(current_hp, max_hp)
signal mana_changed(current_mana, max_mana)
signal dash_cooldown_started(duration)
signal dash_cooldown_updated(time_left)
signal dash_cooldown_finished()
signal susanoo_cooldown_started(duration)
signal susanoo_cooldown_updated(time_left)
signal susanoo_cooldown_finished()
signal room_cooldown_started(duration)
signal room_cooldown_updated(time_left)
signal room_cooldown_finished()
signal giant_cooldown_started(duration)
signal giant_cooldown_updated(time_left)
signal giant_cooldown_finished()
signal susanoo_level_changed(level)
signal room_level_changed(level)
var is_invulnerable: bool = false
var invincible_zone: bool = false
var blade_boomerang_active: bool = false
var can_move: bool = true
var is_in_quicksand: bool = false
const QUICKSAND_COLOR: Color = Color(0.7, 0.6, 0.9, 1.0)  # Màu tím xanh sáng hơn
var _base_movement_speed: float = 0.0
var _base_gravity: float = 0.0
var _base_max_jump_count: int = 0
var decorator_manager: DecoratorManager = null
var hack_mode: HackMode = null
@export var has_blade: bool = false
@export var can_hover: bool = false
@export var has_fire_gem: bool = false
@export var has_water_paw_gem: bool = false
@export var has_water_room_gem: bool = false
@export var susanoo_level: int = 0
@export var room_level: int = 0
@export var max_able_jump = 2
@export var max_jump_count = 2
@export var max_mana : int = 100
var mana : int 
@export var charge_mana_step = 5
@export var mana_regen_interval: float = 0.5   # mỗi 0.5s
@export var mana_regen_amount: int = 1         # cộng 1 mana
var mana_regen_timer: Timer = null             # timer regen
@export var deccel = 800     # ma sát khi ở trên đất
@export var air_deccel = 100   # ma sát khi ở trên không
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_ghost_interval: float = 0.03

# Dash chain limit & cooldown
@export var dash_chain_max: int = 2
@export var dash_chain_cooldown: float = 0.6
var dash_chain_count: int = 0
var dash_on_cooldown: bool = false
var dash_cooldown_timer: Timer = null

@export var room_cooldown_time: float = 20.0
var room_on_cooldown: bool = false
var room_cooldown_timer: Timer = null

var sus_on_cooldown: bool = false
var sus_cooldown_timer: Timer = null

var giant_on_cooldown: bool = false
var giant_cooldown_timer: Timer = null

@export var run_speed_multiplier: float = 1.35
@export var run_double_tap_window_ms: int = 250


@onready var jump_sound = $Jump
@onready var attack_sound = $Attack
@onready var dash_sound = $Dash
@onready var giant_attack_sound = $GiantAttackSound

#giant_mode
@export var giant_damage = 50
@export var giant_speed_multiplier = 1.5
@export var giant_jump_multiplier = 1.5
@export var max_health_giant_multiplier = 2
@onready var is_giant_mode = false
@onready var can_use_giant : bool = true
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hit_collision: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_collision: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D
@onready var effect_sprite: AnimatedSprite2D = $Direction/HealEffect
@onready var transform_giant_sprite: AnimatedSprite2D = $Direction/TransformGiant
@onready var transform_normal_sprite: AnimatedSprite2D = $Direction/TransformNormal
var _orig_max_health: int
var _orig_jump_speed: float
var _orig_attack_damage: float
var _orig_movement_speed: float
var _orig_has_blade: bool 

# Transform interpolation variables
var _is_transforming: bool = false
var _transform_to_giant: bool = false  # true = giant, false = normal
var _transform_timer: float = 0.0
var _transform_duration: float = 0.7  # Thời gian transform (đồng bộ với animation)

# Original collision values for interpolation
const NORMAL_BODY_RADIUS: float = 10.0
const NORMAL_BODY_HEIGHT: float = 30.0
const NORMAL_BODY_POS: Vector2 = Vector2(0.0, -14.0)
const NORMAL_HURT_RADIUS: float = 10.0
const NORMAL_HURT_HEIGHT: float = 30.0
const NORMAL_HURT_POS: Vector2 = Vector2(0.0, -14.0)
const NORMAL_HIT_SIZE: Vector2 = Vector2(35.833, 33.0)
const NORMAL_HIT_POS: Vector2 = Vector2(17.917, -15.5)

const GIANT_BODY_RADIUS: float = 40.0
const GIANT_BODY_HEIGHT: float = 100.0
const GIANT_BODY_POS: Vector2 = Vector2(-11.0, -10.0)
const GIANT_HURT_RADIUS: float = 40.0
const GIANT_HURT_HEIGHT: float = 100.0
const GIANT_HURT_POS: Vector2 = Vector2(-11.0, -10.0)
const GIANT_HIT_SIZE: Vector2 = Vector2(100.0, 90.0)
const GIANT_HIT_POS: Vector2 = Vector2(38.0, -3.839)

#timer
@export var giant_duration = 30
@export var giant_cool_down = 20

#signal take_dame

var _last_left_press_ms: int = -100000
var _last_right_press_ms: int = -100000


var inventory: InvetorySystem
const HEAL_SHADER = preload("res://scenes/character/player/shaders/heal.gdshader")


func get_run_speed() -> float:
	
	return movement_speed * run_speed_multiplier

func check_run_double_tap() -> int:
	var now_ms: int = Time.get_ticks_msec()
	var run_dir: int = 0
	# Detect double-tap left
	if Input.is_action_just_pressed("left"):
		if now_ms - _last_left_press_ms <= run_double_tap_window_ms:
			run_dir = -1
		_last_left_press_ms = now_ms
	# Detect double-tap right
	if Input.is_action_just_pressed("right"):
		if now_ms - _last_right_press_ms <= run_double_tap_window_ms:
			run_dir = 1
		_last_right_press_ms = now_ms
	return run_dir


func _ready() -> void:
	super._ready()
	mana = max_mana
	fsm = FSM.new(self, $States, $States/Idle)
	$Direction/HitArea2D/CollisionShape2D.set_deferred("disabled",true)
		# Register player in GameManager
	GameManager.player = self

	# Decorator manager to apply powerups
	decorator_manager = DecoratorManager.new()
	decorator_manager.initialize(self)
	add_child(decorator_manager)
	hack_mode = HackMode.new()
	add_child(hack_mode)
	if has_blade:
		collected_blade()
	if has_fire_gem:
		collected_fire_gem()
	if has_water_paw_gem:
		collected_water_paw_gem()
	if has_water_room_gem:
		collected_water_room_gem()
	# Always ensure an initial checkpoint exists at game start
	GameManager.ensure_initial_checkpoint()
	# Configure camera soft bottom limit from current stage
	if has_node("Camera2D"):
		var cam: Node = $Camera2D
		var stage = GameManager.current_stage
		if stage != null and cam.has_method("set_soft_bottom_limit") and stage.has_method("get_camera_bottom_limit_y"):
			cam.set_soft_bottom_limit(stage.get_camera_bottom_limit_y())

	# Cache base stats for safe-zone modifications
	_base_movement_speed = movement_speed
	_base_gravity = gravity
	_base_max_jump_count = max_jump_count

	if not GameManager.is_connected("hack_mode_changed", Callable(self, "_on_hack_mode_changed")):
		GameManager.connect("hack_mode_changed", Callable(self, "_on_hack_mode_changed"))
	_on_hack_mode_changed(GameManager.hack_mode_enabled)
	
	# --- Tạo timer tự regen mana ---
	mana_regen_timer = Timer.new()
	mana_regen_timer.wait_time = mana_regen_interval
	mana_regen_timer.one_shot = false
	mana_regen_timer.autostart = true
	mana_regen_timer.timeout.connect(_on_mana_regen_timeout)
	add_child(mana_regen_timer)
	var gm = get_tree().get_root().get_node("GameManager")
	inventory = gm.get_node("InventorySystem")
	
func _physics_process(delta: float) -> void:
	# Apply safe-zone modifiers before physics so gravity uses updated value
	_apply_safe_zone_mods()

	# If player can't move (cutscene), don't update FSM
	if not can_move:
		_update_movement(delta)
		_check_changed_animation()
		_check_changed_direction()
		return

	super._physics_process(delta)
	if is_on_wall() or is_on_floor():
		reset_jump_count()
	
	

func _process(_delta: float) -> void:
	if $Timer/GiantDuration.is_stopped() == false:
		print("Giant time left: ", $Timer/GiantDuration.time_left)
	if dash_on_cooldown and dash_cooldown_timer != null:
		dash_cooldown_updated.emit(dash_cooldown_timer.time_left)
	if sus_on_cooldown and sus_cooldown_timer != null:
		susanoo_cooldown_updated.emit(sus_cooldown_timer.time_left)
	if room_on_cooldown and room_cooldown_timer != null:
		room_cooldown_updated.emit(room_cooldown_timer.time_left)
	if giant_on_cooldown and giant_cooldown_timer != null:
		giant_cooldown_updated.emit(giant_cooldown_timer.time_left)
	
	# Handle transform interpolation
	if _is_transforming:
		_transform_timer += _delta
		var t: float = clamp(_transform_timer / _transform_duration, 0.0, 1.0)
		
		if _transform_to_giant:
			_interpolate_collisions_to_giant(t)
		else:
			_interpolate_collisions_to_normal(t)
		
		# Transform complete
		if t >= 1.0:
			_is_transforming = false
			if _transform_to_giant:
				_on_transform_giant_complete()
			else:
				_on_transform_normal_complete()
	
	# QuickSand shader tint override
	if is_in_quicksand:
		if animated_sprite and animated_sprite.material:
			animated_sprite.material.set_shader_parameter("tint_color", QUICKSAND_COLOR)




func _apply_safe_zone_mods() -> void:
	if is_giant_mode:
		return  # không overwrite stats khi đang giant
	if invincible_zone and room_level >= 2:
		# tốc độ moving x1.5
		movement_speed = _base_movement_speed * 1.5
		# trọng lực giảm 25%
		gravity = _base_gravity * 0.75
	else:
		movement_speed = _base_movement_speed
		gravity = _base_gravity
#Collect powerup to apply to the player
func collect_powerup(powerup_id: String) -> void:
	decorator_manager.apply_powerup(powerup_id)

func set_can_move(value: bool) -> void:
	can_move = value
	if not can_move:
		velocity.x = 0

func can_attack() -> bool:
	#if decorator_manager != null:
		#return decorator_manager.can_blade_attack()
	return has_blade
	
func can_jump() -> bool:
	if invincible_zone and room_level >= 2:
		return true
	return max_jump_count > 0

func consume_jump() -> void:
	if (invincible_zone and room_level >= 2) or GameManager.hack_mode_enabled:
		return
	max_jump_count -= 1

func set_detect_and_hurt_collsion(enable: bool):
	$Direction/HurtArea2D/CollisionShape2D.disabled = not enable
	set_collision_layer_value(2,enable)

func set_hit_collision(enabled):
	$Direction/HitArea2D/CollisionShape2D.disabled = not enabled

func reset_jump_count() -> void:
	if GameManager.hack_mode_enabled:
		max_jump_count = 99999
	else:
		max_jump_count = _base_max_jump_count

func adjust_after_wall_jump() -> void:
	reset_jump_count()
	if GameManager.hack_mode_enabled:
		return
	max_jump_count = 1

func collected_blade() -> void:
	has_blade = true
	set_animated_sprite($Direction/BladeAnimatedSprite2D)

func collected_hover_skill() -> void:
	can_hover = true

func collected_fire_gem() -> void:
	has_fire_gem = true
	if susanoo_level < 1:
		susanoo_level = 1
		susanoo_level_changed.emit(susanoo_level)

func collected_water_paw_gem() -> void:
	has_water_paw_gem = true

func collected_water_room_gem() -> void:
	has_water_room_gem = true
	if room_level < 1:
		room_level = 1
		room_level_changed.emit(room_level)

func save_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"has_blade": has_blade,
		"can_hover": can_hover,
		"has_fire_gem": has_fire_gem,
		"has_water_paw_gem": has_water_paw_gem,
		"has_water_room_gem": has_water_room_gem,
		"susanoo_level": susanoo_level,
		"room_level": room_level
	}

func load_state(data: Dictionary) -> void:
	"""Load player state from checkpoint data"""
	
	# IMPORTANT: Reset all gems and levels to defaults first
	has_fire_gem = false
	can_hover = false
	has_water_paw_gem = false
	has_water_room_gem = false
	susanoo_level = 0
	room_level = 0
	
	# Then apply checkpoint data
	if data.has("position"):
		var pos_array = data["position"]
		global_position = Vector2(pos_array[0], pos_array[1])
	if data.has("has_blade"):
		has_blade = data["has_blade"]
		Dialogic.VAR.set("HasBlade",has_blade)
		if has_blade:
			collected_blade()
	if data.has("can_hover"):
		can_hover = data["can_hover"]
		if can_hover:
			collected_hover_skill()
	if data.has("has_fire_gem"):
		has_fire_gem = data["has_fire_gem"]
		if has_fire_gem:
			collected_fire_gem()
	if data.has("has_water_paw_gem"):
		has_water_paw_gem = data["has_water_paw_gem"]
		if has_water_paw_gem:
			collected_water_paw_gem()
	if data.has("has_water_room_gem"):
		has_water_room_gem = data["has_water_room_gem"]
		if has_water_room_gem:
			collected_water_room_gem()
	if data.has("susanoo_level"):
		susanoo_level = data["susanoo_level"]
		susanoo_level_changed.emit(susanoo_level)
	if data.has("room_level"):
		room_level = data["room_level"]
		room_level_changed.emit(room_level)

func upgrade_susanoo_level() -> void:
	susanoo_level += 1
	susanoo_level_changed.emit(susanoo_level)
	GameManager.update_current_checkpoint_player_state({"susanoo_level": susanoo_level}, true)

func upgrade_room_level() -> void:
	room_level += 1
	room_level_changed.emit(room_level)
	GameManager.update_current_checkpoint_player_state({"room_level": room_level}, true)
			
func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	#take_dame.emit()
	if invincible_zone:
		# Level 3: Immune to all damage
		if room_level >= 3:
			return
		
		# Level 1-2: Take damage but NO KNOCKBACK
		if !is_invulnerable:
			take_damage(_damage, _direction)
			start_invulnerability()
			if health <= 0:
				fsm.change_state(fsm.states.dead)
			# Do NOT enter hurt state (avoids knockback)
		return

	if !is_invulnerable: 
		fsm.current_state.take_damage(_damage, _direction)
		if(health <= 0):
			print("🔴 PLAYER HEALTH <= 0! Changing to dead state...")
			print("Current state: ", fsm.current_state.name if fsm.current_state else "none")
			print("FSM has dead state: ", fsm.states.has("dead"))
			fsm.change_state(fsm.states.dead)
		else: 
			fsm.change_state(fsm.states.hurt)
	#else: 
		#fsm.change_state(fsm.states.immutablebackbounce)

var blink_timer: Timer = null
var inv_cooldown_timer: Timer = null

func start_invulnerability(duration: float = 2.0) -> void:
	if inv_cooldown_timer and inv_cooldown_timer.time_left > 0:
		return  # đang inv, không reset
	is_invulnerable = true 
	set_collision_mask_value(6,true)
	set_collision_layer_value(2,false)
	_start_blink_effect()
	if inv_cooldown_timer == null:
		inv_cooldown_timer = Timer.new()
		inv_cooldown_timer.one_shot = true
		inv_cooldown_timer.timeout.connect(_on_invulnerable_timeout)
		add_child(inv_cooldown_timer)
	inv_cooldown_timer.wait_time = duration
	inv_cooldown_timer.start()

func _on_invulnerable_timeout() -> void:

	is_invulnerable = false
	set_collision_layer_value(2,true)
	set_collision_mask_value(6,false)
	# Chỉ hiển thị sprite đang hoạt động; ẩn các sprite còn lại
	var dir := get_node("Direction")
	if dir:
		for child in dir.get_children():
			if child is AnimatedSprite2D:
				child.visible = false
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.modulate.a = 1.0
	if blink_timer:
		blink_timer.stop()

# Dash gating helpers
func can_dash() -> bool:
	return (not dash_on_cooldown) and (dash_chain_count < dash_chain_max)

func can_heal() -> bool:
	return health < max_health

func can_charge_mana() -> bool:
	return mana < max_mana

func register_dash_started() -> void:
	dash_chain_count += 1

func register_dash_finished() -> void:
	if dash_chain_count >= dash_chain_max and not dash_on_cooldown:
		start_dash_cooldown()

func start_dash_cooldown() -> void:
	dash_on_cooldown = true
	if dash_cooldown_timer == null:
		dash_cooldown_timer = Timer.new()
		dash_cooldown_timer.one_shot = true
		dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
		add_child(dash_cooldown_timer)
	dash_cooldown_timer.wait_time = dash_chain_cooldown
	dash_cooldown_timer.start()
	dash_cooldown_started.emit(dash_chain_cooldown)

func _on_dash_cooldown_timeout() -> void:
	dash_on_cooldown = false
	dash_chain_count = 0
	dash_cooldown_finished.emit()

func start_susanoo_cooldown() -> void:
	sus_on_cooldown = true
	if sus_cooldown_timer == null:
		sus_cooldown_timer = Timer.new()
		sus_cooldown_timer.one_shot = true
		sus_cooldown_timer.timeout.connect(_on_susanoo_cooldown_timeout)
		add_child(sus_cooldown_timer)
	sus_cooldown_timer.wait_time = 20.0  # Fixed to 20 seconds
	sus_cooldown_timer.start()
	susanoo_cooldown_started.emit(20.0)

func start_room_cooldown() -> void:
	room_on_cooldown = true
	if room_cooldown_timer == null:
		room_cooldown_timer = Timer.new()
		room_cooldown_timer.one_shot = true
		room_cooldown_timer.timeout.connect(_on_room_cooldown_timeout)
		add_child(room_cooldown_timer)
	room_cooldown_timer.wait_time = 20.0  # Fixed to 20 seconds
	room_cooldown_timer.start()
	room_cooldown_started.emit(20.0)

func start_giant_cooldown() -> void:
	giant_on_cooldown = true
	if giant_cooldown_timer == null:
		giant_cooldown_timer = Timer.new()
		giant_cooldown_timer.one_shot = true
		giant_cooldown_timer.timeout.connect(_on_giant_cooldown_timeout)
		add_child(giant_cooldown_timer)
	giant_cooldown_timer.wait_time = giant_cool_down
	giant_cooldown_timer.start()
	giant_cooldown_started.emit(giant_cool_down)

func _on_susanoo_cooldown_timeout() -> void:
	sus_on_cooldown = false
	susanoo_cooldown_finished.emit()

func _on_room_cooldown_timeout() -> void:
	room_on_cooldown = false
	room_cooldown_finished.emit()

func _start_blink_effect() -> void:
	if blink_timer == null:
		blink_timer = Timer.new()
		blink_timer.wait_time = 0.1  # chớp mỗi 0.1 giây
		blink_timer.timeout.connect(_on_blink_timer_timeout)
		add_child(blink_timer)
	blink_timer.start()

func _on_blink_timer_timeout() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.modulate.a == 1.0:
		animated_sprite.modulate.a = 0.4  # giảm alpha để nhấp nháy
	else:
		animated_sprite.modulate.a = 1.0  # phục hồi alpha


func _on_fall_hurt_area_2d_hurt(direction: Vector2, damage: float) -> void:
	if invincible_zone:
		return
	fsm.current_state.take_damage(damage, direction)
	if(health <= 0):
		fsm.change_state(fsm.states.dead)
	else: 
		fsm.change_state(fsm.states.hurt)
		

func _on_hack_mode_changed(enabled: bool) -> void:
	if enabled:
		hack_mode.apply(self)
	else:
		hack_mode.remove(self)

func activate_hack_mode() -> void:
	hack_mode.apply(self)

func deactivate_hack_mode() -> void:
	hack_mode.remove(self)

func get_movement_speed():
	if decorator_manager != null:
		return decorator_manager.get_effective_movement_speed()
	return movement_speed
	
		
func get_jump_speed():
	if decorator_manager != null:
		return decorator_manager.get_effective_jump_speed()
	return jump_speed
	
func speed_up(multiplier: float, duration: float) -> void:
	movement_speed = movement_speed * multiplier
	await get_tree().create_timer(duration).timeout
	movement_speed = movement_speed / multiplier
	

func take_damage(damage: int, hit_direction: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(damage, hit_direction)
	emit_signal("hp_changed", health, max_health)

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	emit_signal("hp_changed", health, max_health)
	
func take_mana(amount: int ) -> void:
	mana -= amount
	emit_signal("mana_changed", mana, max_mana)
	
func charge_mana(amount: int) -> void:
	mana = min(mana + amount, max_mana)
	emit_signal("mana_changed", mana, max_mana)

func can_use_skill(amount: int) -> bool:
	return mana >= amount 

func _on_hit_area_2d_hitted(area: Variant) -> void:
	charge_mana(charge_mana_step)

func _on_mana_regen_timeout() -> void:
	# chỉ regen nếu chưa full
	if mana < max_mana:
		charge_mana(mana_regen_amount)
		
# giant_foxy
func activate_giant_form() -> void:
	# ----- SAVE ORIGINAL STATES -----
	_orig_jump_speed = jump_speed
	_orig_attack_damage = $Direction/HitArea2D.damage
	_orig_movement_speed = movement_speed
	_orig_has_blade = has_blade
	_orig_max_health = max_health
	
	# ----- START TRANSFORM ANIMATION -----
	animated_sprite.visible = false
	transform_giant_sprite.visible = true
	transform_giant_sprite.play("default")
	
	# Play transform sound
	$TransformSound.play()
	
	# ----- START COLLISION INTERPOLATION (song song với animation) -----
	_is_transforming = true
	_transform_to_giant = true
	_transform_timer = 0.0
	can_move = false  # Tắt input khi đang transform
	
	# ----- APPLY GIANT MODE STATS IMMEDIATELY -----
	is_giant_mode = true
	print("Activate Giant Form for: ", giant_duration, " seconds")
	has_blade = true
	$Direction/HitArea2D.damage = giant_damage
	
	max_health *= max_health_giant_multiplier
	health = (health * 100 / _orig_max_health) * max_health / 100
	emit_signal("hp_changed", health, max_health)
	movement_speed *= giant_speed_multiplier
	jump_speed *= giant_jump_multiplier
	$Timer/GiantDuration.start(giant_duration)

func _on_transform_giant_complete() -> void:
	# Khi transform hoàn thành
	transform_giant_sprite.visible = false
	animated_sprite.visible = true
	set_animated_sprite($Direction/GiantAnimatedSprite2D)
	can_move = true  # Bật lại input khi transform xong
	# Đảm bảo collision cuối cùng chính xác
	_set_giant_collisions()

func _interpolate_collisions_to_giant(t: float) -> void:
	# Interpolate body collision
	var body_shape := body_collision.shape as CapsuleShape2D
	body_shape.radius = lerp(NORMAL_BODY_RADIUS, GIANT_BODY_RADIUS, t)
	body_shape.height = lerp(NORMAL_BODY_HEIGHT, GIANT_BODY_HEIGHT, t)
	body_collision.position = NORMAL_BODY_POS.lerp(GIANT_BODY_POS, t)
	
	# Interpolate hurt collision
	var hurt_shape := hurt_collision.shape as CapsuleShape2D
	hurt_shape.radius = lerp(NORMAL_HURT_RADIUS, GIANT_HURT_RADIUS, t)
	hurt_shape.height = lerp(NORMAL_HURT_HEIGHT, GIANT_HURT_HEIGHT, t)
	hurt_collision.position = NORMAL_HURT_POS.lerp(GIANT_HURT_POS, t)
	
	# Interpolate hit collision
	var hit_shape := hit_collision.shape as RectangleShape2D
	hit_shape.size = NORMAL_HIT_SIZE.lerp(GIANT_HIT_SIZE, t)
	hit_collision.position = NORMAL_HIT_POS.lerp(GIANT_HIT_POS, t)

func _set_giant_collisions() -> void:
	var body_shape := body_collision.shape as CapsuleShape2D
	body_shape.radius = GIANT_BODY_RADIUS
	body_shape.height = GIANT_BODY_HEIGHT
	body_collision.position = GIANT_BODY_POS
	
	var hurt_shape := hurt_collision.shape as CapsuleShape2D
	hurt_shape.radius = GIANT_HURT_RADIUS
	hurt_shape.height = GIANT_HURT_HEIGHT
	hurt_collision.position = GIANT_HURT_POS
	
	var hit_shape := hit_collision.shape as RectangleShape2D
	hit_shape.size = GIANT_HIT_SIZE
	hit_collision.position = GIANT_HIT_POS


func inactive_giant_form():
	# ----- START TRANSFORM ANIMATION -----
	animated_sprite.visible = false
	transform_normal_sprite.visible = true
	transform_normal_sprite.play("default")
	
	# Play transform sound
	$TransformSound.play()
	
	# ----- START COLLISION INTERPOLATION (song song với animation) -----
	_is_transforming = true
	_transform_to_giant = false
	_transform_timer = 0.0
	can_move = false  # Tắt input khi đang transform
	
	# ----- RESET GIANT STATE IMMEDIATELY -----
	is_giant_mode = false
	has_blade = _orig_has_blade
	jump_speed = _orig_jump_speed
	$Direction/HitArea2D.damage = _orig_attack_damage
	movement_speed = _orig_movement_speed

	health = min((health * 100 / max_health) * _orig_max_health / 100, _orig_max_health)
	max_health = _orig_max_health
	emit_signal("hp_changed", health, max_health)
	
	# Cooldown
	can_use_giant = false
	start_giant_cooldown()

func _on_transform_normal_complete() -> void:
	# Khi transform hoàn thành
	transform_normal_sprite.visible = false
	animated_sprite.visible = true
	set_animated_sprite($Direction/BladeAnimatedSprite2D)
	can_move = true  # Bật lại input khi transform xong
	# Đảm bảo collision cuối cùng chính xác
	_restore_collision_shape()

func _interpolate_collisions_to_normal(t: float) -> void:
	# Interpolate body collision
	var body_shape := body_collision.shape as CapsuleShape2D
	body_shape.radius = lerp(GIANT_BODY_RADIUS, NORMAL_BODY_RADIUS, t)
	body_shape.height = lerp(GIANT_BODY_HEIGHT, NORMAL_BODY_HEIGHT, t)
	body_collision.position = GIANT_BODY_POS.lerp(NORMAL_BODY_POS, t)
	
	# Interpolate hurt collision
	var hurt_shape := hurt_collision.shape as CapsuleShape2D
	hurt_shape.radius = lerp(GIANT_HURT_RADIUS, NORMAL_HURT_RADIUS, t)
	hurt_shape.height = lerp(GIANT_HURT_HEIGHT, NORMAL_HURT_HEIGHT, t)
	hurt_collision.position = GIANT_HURT_POS.lerp(NORMAL_HURT_POS, t)
	
	# Interpolate hit collision
	var hit_shape := hit_collision.shape as RectangleShape2D
	hit_shape.size = GIANT_HIT_SIZE.lerp(NORMAL_HIT_SIZE, t)
	hit_collision.position = GIANT_HIT_POS.lerp(NORMAL_HIT_POS, t)

func _restore_collision_shape() -> void:
	var body_shape := body_collision.shape as CapsuleShape2D
	body_shape.radius = NORMAL_BODY_RADIUS
	body_shape.height = NORMAL_BODY_HEIGHT
	body_collision.position = NORMAL_BODY_POS

	var hurt_shape := hurt_collision.shape as CapsuleShape2D
	hurt_shape.radius = NORMAL_HURT_RADIUS
	hurt_shape.height = NORMAL_HURT_HEIGHT
	hurt_collision.position = NORMAL_HURT_POS

	var hit_shape := hit_collision.shape as RectangleShape2D
	hit_shape.size = NORMAL_HIT_SIZE
	hit_collision.position = NORMAL_HIT_POS


func _on_giant_duration_timeout() -> void:
	inactive_giant_form()


func _on_giant_cooldown_timeout() -> void:
	giant_on_cooldown = false
	can_use_giant = true
	giant_cooldown_finished.emit()


func use_heal_potion(amount: int) -> void:
	if GameManager.inventory_system.use_heal_potion():
		$HealSound.play()
		heal(amount)
		play_heal_effect()
		
func play_heal_effect():
	if is_giant_mode:
		effect_sprite.scale = Vector2(0.7,0.7)
	else:
		effect_sprite.scale = Vector2(0.3,0.3)
	effect_sprite.visible = true
	effect_sprite.play("heal")
	await effect_sprite.animation_finished
	effect_sprite.visible = false

# QuickSand methods
func enter_quicksand(speed_multiplier: float = 0.5) -> void:
	is_in_quicksand = true
	_base_movement_speed = _base_movement_speed * speed_multiplier
	movement_speed = _base_movement_speed
	print("[Player] Entered QuickSand - Speed: ", movement_speed)
	# Set shader tint
	if animated_sprite and animated_sprite.material:
		animated_sprite.material.set_shader_parameter("tint_color", QUICKSAND_COLOR)

func exit_quicksand(original_speed: float) -> void:
	is_in_quicksand = false
	_base_movement_speed = original_speed
	movement_speed = original_speed
	# Reset shader tint to white (no tint)
	if animated_sprite and animated_sprite.material:
		animated_sprite.material.set_shader_parameter("tint_color", Color.WHITE)
	print("[Player] Exited QuickSand - Speed: ", movement_speed)
