extends EnemyCharacter

signal hit_boss
signal hit_player

@export var speed: float = 400.0
@export var max_range: float = 800.0
@export var spike_damage: int = 10
@export var rotation_speed: float = 720.0  
@export var return_stop_radius: float = 10.0

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D

var origin: Vector2
var boss_position: Vector2
var player_target_pos: Vector2
var going_out := true
var owner_crab: Node = null
var traveled := 0.0
var dir: Vector2 = Vector2.RIGHT
var rotation_angle := 0.0
var has_hit_boss := false

func _ready() -> void:
	if hit_area_2d:
		hit_area_2d.damage = spike_damage
	gravity = 0.0

func _update_movement(delta: float) -> void:
	move_and_slide()

func launch(_owner: Node, _origin: Vector2, _target: Vector2) -> void:
	owner_crab = _owner
	origin = _origin
	global_position = _origin
	target_pos = _target

	# Store the boss's current position for return check
	if owner_crab and owner_crab.obj:
		boss_position = owner_crab.obj.global_position
	else:
		boss_position = _origin  # fallback to origin if no boss reference

	dir = (_target - origin).normalized()
	velocity = dir * speed
	_face_by_dir(dir)

func _physics_process(delta: float) -> void:
	if not has_hit_boss:
		rotation_angle += rotation_speed * delta
		if has_node("Direction"):
			$Direction.rotation_degrees = rotation_angle

	if going_out and not has_hit_boss:
		traveled += speed * delta
		if _hit_wall() or traveled >= max_range or global_position.distance_to(origin) >= max_range:
			going_out = false
			dir = (boss_position - global_position).normalized()
			_face_by_dir(dir)
	elif not has_hit_boss:
		if global_position.distance_to(boss_position) <= return_stop_radius:
			hit_the_boss()
			return

	velocity = dir * speed
	_face_by_dir(dir)

	super._physics_process(delta)

func _hit_wall() -> bool:
	return is_on_wall()

func _face_by_dir(d: Vector2) -> void:
	if d.x > 0.0:
		change_direction(-1)
	elif d.x < 0.0:
		change_direction(1)

func hit_the_boss() -> void:
	if has_hit_boss:
		return

	has_hit_boss = true
	emit_signal("hit_boss")

	queue_free()
