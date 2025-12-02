extends EnemyCharacter

@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var hurt_area = $Direction/HurtArea2D

@export var minion_health: int = 100

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	super._on_hurt_area_2d_hurt(_direction, _damage)

	if health <= 0:
		fsm.change_state(fsm.states.dead)
	else:
		fsm.change_state(fsm.states.hurt)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if can_detect_player():
		if fsm.current_state != fsm.states.attack:
			fsm.change_state(fsm.states.attack)
	
	if health <= 0:
		fsm.change_state(fsm.states.dead)

func can_detect_player() -> bool:
	var front_hit := false

	if detect_front.is_colliding():
		var obj = detect_front.get_collider()
		if obj is Player:
			front_hit = true

	if detect_back.is_colliding():
		var obj = detect_back.get_collider()
		if obj is Player:
			turn_around()
			_check_changed_direction()

	return front_hit
