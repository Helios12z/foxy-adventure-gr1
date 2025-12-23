extends EnemyCharacter

@export var bullet_speed: float = 300.0
@export var max_range: float = 320.0
@export var bullet_damage: int = 30

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D

var dir: Vector2 = Vector2.RIGHT
var going_out := true
var traveled := 0.0
var origin: Vector2

func _ready() -> void:
	hit_area_2d.damage = bullet_damage
	gravity = 0.0

func _update_movement(delta: float) -> void:
	move_and_slide()

func launch(_origin: Vector2, _direction: Vector2) -> void:
	origin = _origin
	global_position = _origin

	if _direction.length_squared() <= 0.000001:
		_direction = Vector2.RIGHT

	dir = _direction.normalized()
	velocity = dir * bullet_speed
	_face_by_dir(dir)

func _physics_process(delta: float) -> void:
	if going_out:
		traveled += bullet_speed * delta
		if _hit_wall() or traveled >= max_range or global_position.distance_to(origin) >= max_range:
			going_out = false
			dir = (origin - global_position).normalized()
			_face_by_dir(dir)
	else:
		queue_free()
		return

	velocity = dir * bullet_speed
	_face_by_dir(dir)

	super._physics_process(delta)

func _hit_wall() -> bool:
	return is_on_wall()

func _face_by_dir(d: Vector2) -> void:
	if d.x > 0.0:
		change_direction(-1)
	elif d.x < 0.0:
		change_direction(1)
