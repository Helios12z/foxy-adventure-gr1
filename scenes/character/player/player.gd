class_name Player
extends BaseCharacter

## Player character class that handles movement, combat, and state management
var is_invulnerable: bool = false
@export var has_blade: bool = false
@export var max_jump_count = 2
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

@export var run_speed_multiplier: float = 1.35
@export var run_double_tap_window_ms: int = 250
var _last_left_press_ms: int = -100000
var _last_right_press_ms: int = -100000

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
	
	fsm = FSM.new(self, $States, $States/Idle)
	$Direction/HitArea2D/CollisionShape2D.set_deferred("disabled",true)
	GameManager.player = self
	if has_blade:
		collected_blade()
	# Always ensure an initial checkpoint exists at game start
	GameManager.ensure_initial_checkpoint()
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_on_wall() or is_on_floor():
		reset_jump_count()

func can_attack() -> bool:
	return has_blade
	
func can_jump() -> bool:
	if max_jump_count > 0:
		return true
	return false

func set_detect_and_hurt_collsion(enable: bool):
	$Direction/HurtArea2D/CollisionShape2D.disabled = not enable
	set_collision_layer_value(2,enable)

func set_hit_collision(enabled):
	$Direction/HitArea2D/CollisionShape2D.disabled = not enabled

func reset_jump_count() -> void:
	max_jump_count = 2

func collected_blade() -> void:
	has_blade = true
	set_animated_sprite($Direction/BladeAnimatedSprite2D)

func save_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"has_blade": has_blade
	}

func load_state(data: Dictionary) -> void:
	"""Load player state from checkpoint data"""
	if data.has("position"):
		var pos_array = data["position"]
		global_position = Vector2(pos_array[0], pos_array[1])
	if data.has("has_blade"):
		has_blade = data["has_blade"]
		if has_blade:
			collected_blade()
			
func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	if !is_invulnerable: 
		fsm.current_state.take_damage(_damage)
		if(health <= 0):
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

func _on_dash_cooldown_timeout() -> void:
	dash_on_cooldown = false
	dash_chain_count = 0

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
