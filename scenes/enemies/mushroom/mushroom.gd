extends EnemyCharacter
@onready var hurt_area = $Direction/HurtArea2D

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	fsm.current_state.take_damage(_direction, _damage)
