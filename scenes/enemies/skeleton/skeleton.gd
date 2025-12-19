extends EnemyCharacter

@export var minion_health: int = 100
@export var revive_delay: float = 1.75
@export var healthbar_gray: Color = Color(0.65, 0.65, 0.65, 1.0)

@onready var detect_front: RayCast2D = $Direction/DetectFrontRayCast2D
@onready var detect_back: RayCast2D = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast: RayCast2D = $Direction/AttackScopeRayCast2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

var is_in_temporary_dead: bool = false
var finished_in_temporary_dead: bool = false
var is_dead: bool = false

var _healthbar_base_modulate: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	max_health = minion_health
	health = max_health

	super._ready()

	fsm = FSM.new(self, $States, $States/Walk)
	set_hit_collision(false)

	if _health_bar:
		_healthbar_base_modulate = _health_bar.modulate
	_apply_healthbar_color()

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

func _take_damage_from_dir(_damage_dir: Vector2, _damage: float) -> void:
	if is_dead:
		return

	var dmg := int(_damage)
	health -= dmg

	_update_health_bar_after_damage()

	if health > 0:
		_apply_healthbar_color()
		fsm.change_state(fsm.states.hurt)
		return

	if is_in_temporary_dead:
		finished_in_temporary_dead = true
		is_dead = true
		_apply_healthbar_color()
		fsm.change_state(fsm.states.dead)
		return

	is_in_temporary_dead = true
	finished_in_temporary_dead = false

	health = 1
	_update_health_bar_after_damage()
	_apply_healthbar_color()

	fsm.change_state(fsm.states.temporarydead)

func _apply_healthbar_color() -> void:
	if _health_bar == null:
		return

	if is_in_temporary_dead and not is_dead:
		_health_bar.modulate = healthbar_gray
	else:
		_health_bar.modulate = _healthbar_base_modulate

func set_healthbar_temporary_dead_visual() -> void:
	is_in_temporary_dead = true
	_apply_healthbar_color()

func reset_healthbar_visual() -> void:
	is_in_temporary_dead = false
	_apply_healthbar_color()
