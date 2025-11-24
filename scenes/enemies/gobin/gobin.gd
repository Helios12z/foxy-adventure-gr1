extends EnemyCharacter
@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast = $Direction/AttackScopeRayCast2D
@onready var hurt_area = $Direction/HurtArea2D

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	max_health = 10
	set_hit_collision(false)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	# Đảm bảo là Vector2 và chuẩn hoá
	var dir = _direction if _direction is Vector2 else Vector2.ZERO
	knockback_direction = dir.normalized() if dir.length() > 0.0001 else Vector2.ZERO

	fsm.current_state.take_damage(knockback_direction, _damage)
	fsm.change_state(fsm.states.hurt)

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
