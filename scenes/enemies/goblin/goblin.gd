extends EnemyCharacter

@export var minion_health: int = 100
@export var retreat_speed: float = 180.0
@export var goblin_scene: PackedScene

@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast = $Direction/AttackScopeRayCast2D
@onready var hurt_area = $Direction/HurtArea2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

var spawn_position: Vector2  # Store original spawn position
var can_retreat: bool = true  # Can this goblin enter retreat state? (false for spawned reinforcements)
var has_summoned_reinforcements: bool = false  # Has this goblin already spawned reinforcements? (one-time only)

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	set_hit_collision(false)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)
	# Store spawn position
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

# Check if should retreat (health below 70% and allowed to retreat)
func should_retreat() -> bool:
	return can_retreat and health < max_health * 0.7

# Get spawn position
func get_spawn_position() -> Vector2:
	return spawn_position

func can_detect_player() -> bool:
	# Kiểm tra nếu ray phía trước hoặc phía sau chạm Player
	if detect_front.is_colliding():
		var obj = detect_front.get_collider()
		return true

	if detect_back.is_colliding():
		var obj = detect_back.get_collider()
		turn_around()
		_check_changed_direction()
		return true

	return false

# check player in attack scope
func is_in_attack_scope() -> bool:
	if attack_scope_ray_cast.is_colliding():
		return true
	return false
