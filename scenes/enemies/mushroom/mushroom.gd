extends EnemyCharacter

@export var minion_health: int = 50

@onready var hurt_area = $Direction/HurtArea2D

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
