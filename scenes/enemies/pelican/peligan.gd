extends EnemyCharacter

@export var minion_health: int = 25
@export var bullet_speed: float = -200
@onready var bullet_factory := $Direction/BulletFactory


func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Fly)
	max_health = minion_health
	super._ready()
	
func fire() -> void:
	var bullet := bullet_factory.create() as RigidBody2D
	var shooting_velocity := Vector2(direction * 100, bullet_speed)
	bullet.apply_impulse(shooting_velocity)
	
