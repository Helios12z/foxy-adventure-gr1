extends EnemyCharacter
@export var bullet_speed: float = -200
@onready var bullet_factory := $Direction/BulletFactory


func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Fly)
	super._ready()
func fire() -> void:
	var bullet := bullet_factory.create() as RigidBody2D
	var shooting_velocity := Vector2(direction * 100, bullet_speed)
	bullet.apply_impulse(shooting_velocity)

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float) -> void:
	fsm.current_state.take_damage(_direction, _damage)
	
