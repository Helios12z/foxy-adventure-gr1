extends EnemyCharacter

@export var bullet: PackedScene
@export var minion_health: int = 100

@onready var detect_front: RayCast2D = $Direction/DetectFrontRayCast2D
@onready var detect_back: RayCast2D = $Direction/DetectBackRayCast2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var hurt_area = $Direction/HurtArea2D
@onready var shoot_point: Marker2D = $Direction/ShootPoint

func _ready() -> void:
	max_health = minion_health
	health = max_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	set_hit_collision(false)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func can_detect_player() -> bool:
	if detect_front.is_colliding():
		return true

	if detect_back.is_colliding():
		turn_around()
		_check_changed_direction()
		return true

	return false

func shoot_bullet() -> void:
	if bullet == null:
		return

	var player = get_tree().get_first_node_in_group("Player") as Player
	if player == null:
		return

	var bullet_instance = bullet.instantiate() as RigidBody2D
	var parent = get_parent()
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(bullet_instance)

	bullet_instance.global_position = shoot_point.global_position

	var direction_to_player = (player.global_position - bullet_instance.global_position).normalized()
	var speed = 300.0
	bullet_instance.linear_velocity = direction_to_player * speed

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float) -> void:
	_take_damage_from_dir(_direction, _damage)
