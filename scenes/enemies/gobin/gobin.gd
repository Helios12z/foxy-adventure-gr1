extends EnemyCharacter

@export var minion_health: int = 100

@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast = $Direction/AttackScopeRayCast2D
@onready var hurt_area = $Direction/HurtArea2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	set_hit_collision(false)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

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
