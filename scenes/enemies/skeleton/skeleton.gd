extends EnemyCharacter

@export var minion_health: int = 100
@export var revive_delay: float = 1.75

@onready var detect_front: RayCast2D = $Direction/DetectFrontRayCast2D
@onready var detect_back: RayCast2D = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast: RayCast2D = $Direction/AttackScopeRayCast2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

func _ready() -> void:
	if animated_sprite_2d.material is ShaderMaterial:
		animated_sprite_2d.material = animated_sprite_2d.material.duplicate()
	_reset_dissolve_shader()

	max_health = minion_health
	health = max_health

	super._ready()

	fsm = FSM.new(self, $States, $States/Walk)
	set_hit_collision(false)

func can_detect_player() -> bool:
	if detect_front.is_colliding():
		return true

	if detect_back.is_colliding():
		turn_around()
		_check_changed_direction()
		return true

	return false

func is_in_attack_scope() -> bool:
	return attack_scope_ray_cast.is_colliding()
	
func _reset_dissolve_shader() -> void:
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("progress", 1.0)
