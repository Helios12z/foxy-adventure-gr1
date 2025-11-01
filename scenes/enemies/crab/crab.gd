extends EnemyCharacter
@onready var hurt_area = $Direction/HurtArea2D

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	health = 10
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	# Đảm bảo là Vector2 và chuẩn hoá
	var dir = _direction if _direction is Vector2 else Vector2.ZERO
	knockback_direction = dir.normalized() if dir.length() > 0.0001 else Vector2.ZERO

	fsm.current_state.take_damage(knockback_direction, _damage)
	print("hurt")
	print(health)

	if health <= 0:
		fsm.change_state(fsm.states.dead)
	else:
		fsm.change_state(fsm.states.hurt)
