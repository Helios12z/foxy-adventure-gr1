extends EnemyCharacter

@export var pear_attack_damage: int = 50 
@export var pear_health: int = 300 
@export var sight: int = 100
@export var move_speed: int = 50 
@export var attack_distance: float = 40.0
@export var spike_damage: int = 150
@export var turn_time: float = 1.25 

@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var hurt_area = $Direction/HurtArea2D
@onready var spear_collision_shape_2d: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var spike_hit_area_2d: HitArea2D = $Direction/SpikeHitArea2D

var _waiting_turn_from_back: bool = false
var _turn_timer: float = 0.0

func _ready() -> void:
	super._ready()
	change_direction(-direction)
	collision_shape_2d.position.x *= -1

	fsm = FSM.new(self, $States, $States/Walk)
	health = pear_health
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt) 
	hit_area_2d.damage = pear_attack_damage
	spear_collision_shape_2d.disabled = true
	spike_hit_area_2d.damage = spike_damage

func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	var dir = _direction if _direction is Vector2 else Vector2.ZERO
	knockback_direction = dir.normalized() if dir.length() > 0.0001 else Vector2.ZERO
	fsm.current_state.take_damage(knockback_direction, _damage)

	if health <= 0:
		fsm.change_state(fsm.states.dead)
	else:
		fsm.change_state(fsm.states.hurt)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _waiting_turn_from_back:
		_turn_timer -= delta
		if _turn_timer <= 0.0:
			_waiting_turn_from_back = false
			turn_around()
			collision_shape_2d.position.x *= -1
			_check_changed_direction()

func can_detect_player() -> bool:
	if detect_front.is_colliding():
		var obj = detect_front.get_collider()
		if obj and obj is Node2D:
			if absf(obj.global_position.x - global_position.x) <= 10:
				fsm.change_state(fsm.states.attack)
		return true

	if detect_back.is_colliding():
		var obj = detect_back.get_collider()
		if obj and obj is Node2D:
			if not _waiting_turn_from_back:
				_waiting_turn_from_back = true
				_turn_timer = turn_time
		return true

	return false
