extends EnemyCharacter

signal returned

@export var speed: float = 300.0
@export var max_range: float = 320.0
@export var spike_damage: int = 30
@export var return_stop_radius: float = 6.0

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var detect_area_2d: Area2D = $Direction/DetectArea2D

var origin: Vector2
var target_corner: Vector2
var going_out := true
var owner_crab: Node = null
var traveled := 0.0
var dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	hit_area_2d.damage = spike_damage
	gravity = 0.0
	detect_area_2d.connect("area_entered", Callable(self, "_on_detect_area_entered"))

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

func _physics_process(delta: float) -> void:
	if going_out:
		traveled += speed * delta
		if _hit_wall() or traveled >= max_range or global_position.distance_to(origin) >= max_range:
			going_out = false
			dir = (origin - global_position).normalized()
			_face_by_dir(dir)
	else:
		if global_position.distance_to(origin) <= return_stop_radius:
			print("DEBUG: Claw returning to origin, emitting returned signal. Groups before removal: ", get_groups())
			emit_signal("returned")
			print("DEBUG: After emitting returned signal, about to queue_free")
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

func _on_detect_area_entered(area: Area2D) -> void:
	var other_direction = area.get_parent()
	var other_claw = other_direction.get_parent()

	if other_claw != self and other_claw is EnemyCharacter:
		if is_in_group("atk4_first_claw") and other_claw.is_in_group("atk4_second_claw"):
			owner_crab._on_claws_collided(self, other_claw)
		elif is_in_group("atk4_second_claw") and other_claw.is_in_group("atk4_first_claw"):
			owner_crab._on_claws_collided(self, other_claw)
