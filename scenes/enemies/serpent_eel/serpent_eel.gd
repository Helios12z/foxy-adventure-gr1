extends EnemyCharacter

@export var minion_health: int = 100
@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 2.0
@export var attack_cooldown: float = 9.0

@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast = $Direction/AttackScopeRayCast2D
@onready var hurt_area = $Direction/HurtArea2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

var _bob_t: float = 0.0
var _base_sprite_y: float = 0.0
var attack_cooldown_timer: float = 0.0

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)
	detect_front.enabled = true
	detect_back.enabled = true
	attack_scope_ray_cast.enabled = true
	_base_sprite_y = animated_sprite_2d.position.y

func _process(delta: float) -> void:
	_bob_t += delta
	animated_sprite_2d.position.y = _base_sprite_y + sin(_bob_t * bob_speed) * bob_amplitude
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = max(attack_cooldown_timer - delta, 0.0)

func can_detect_player() -> bool:
	if detect_front.is_colliding():
		var obj = detect_front.get_collider()
		return true

	if detect_back.is_colliding():
		var obj = detect_back.get_collider()
		turn_around()
		_check_changed_direction()
		return true

	return false

func is_in_attack_scope() -> bool:
	if attack_scope_ray_cast.is_colliding():
		return true
	return false

func start_attack_cooldown() -> void:
	attack_cooldown_timer = attack_cooldown
