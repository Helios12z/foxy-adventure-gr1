extends EnemyCharacter

signal returned
signal hit_player

@export var speed: float = 300.0
@export var max_range: float = 320.0
@export var spike_damage: int = 1
@export var return_stop_radius: float = 6.0

var origin: Vector2
var target_corner: Vector2
var going_out := true
var owner_crab: Node = null
var traveled := 0.0
var dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	gravity = 0.0

#no gravity count
func _update_movement(delta: float) -> void:
	move_and_slide()

func launch(_owner: Node, _origin: Vector2, _target: Vector2) -> void:
	owner_crab = _owner
	origin = _origin
	global_position = _origin
	target_corner = _target

	dir = (target_corner - origin).normalized()
	velocity = dir * speed
	_face_by_dir(dir) 

	if owner_crab and owner_crab.has_method("on_claw_launched"):
		owner_crab.on_claw_launched(origin)

func _physics_process(delta: float) -> void:
	if going_out:
		traveled += speed * delta
		if _hit_wall() or traveled >= max_range or global_position.distance_to(origin) >= max_range:
			going_out = false
			dir = (origin - global_position).normalized()
			_face_by_dir(dir)
	else:
		if global_position.distance_to(origin) <= return_stop_radius:
			if owner_crab and owner_crab.has_method("on_claw_returned"):
				owner_crab.on_claw_returned()
			emit_signal("returned")
			queue_free()
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

func _on_body_entered(body: Node) -> void:
	if body is Player:
		emit_signal("hit_player")
