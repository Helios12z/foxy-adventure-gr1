class_name Player
extends BaseCharacter

## Player character class that handles movement, combat, and state management
var is_invulnerable: bool = false
@export var has_blade: bool = false
@export var max_jump_count = 2
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_ghost_interval: float = 0.03

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	if has_blade:
		collected_blade()
	GameManager.player = self
	$HurtArea2D.hurt.connect(_on_hurt_area_2d_hurt)

func can_attack() -> bool:
	return has_blade
	
func can_jump() -> bool:
	if max_jump_count > 0:
		return true
	return false

func reset_jump_count() -> void:
	max_jump_count = 2

func collected_blade() -> void:
	has_blade = true
	set_animated_sprite($Direction/BladeAnimatedSprite2D)

func save_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y]
	}

func load_state(data: Dictionary) -> void:
	"""Load player state from checkpoint data"""
	if data.has("position"):
		var pos_array = data["position"]
		global_position = Vector2(pos_array[0], pos_array[1])
			
func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	if !is_invulnerable: 
		fsm.current_state.take_damage(_damage)
		print("hurt")
		print(health)
		if(health <= 0):
			fsm.change_state(fsm.states.dead)
		else: 
			fsm.change_state(fsm.states.hurt)
	else: 
		fsm.change_state(fsm.states.immutablebackbounce)

var inv_cooldown_timer: Timer = null
var blink_timer: Timer = null

func start_invulnerability(duration: float = 2.0) -> void:
	if inv_cooldown_timer and inv_cooldown_timer.time_left > 0:
		return  # đang inv, không reset
	is_invulnerable = true
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
	$Direction/AnimatedSprite2D.visible = true  # đảm bảo hiện lại
	if blink_timer:
		blink_timer.stop()

func _start_blink_effect() -> void:
	if blink_timer == null:
		blink_timer = Timer.new()
		blink_timer.wait_time = 0.1  # chớp mỗi 0.1 giây
		blink_timer.timeout.connect(_on_blink_timer_timeout)
		add_child(blink_timer)
	blink_timer.start()

func _on_blink_timer_timeout() -> void:
	var sprite = $Direction/AnimatedSprite2D
	if sprite.modulate.a == 1.0:
		sprite.modulate.a = 0.4  # giảm alpha để nhấp nháy
	else:
		sprite.modulate.a = 1.0  # phục hồi alpha
