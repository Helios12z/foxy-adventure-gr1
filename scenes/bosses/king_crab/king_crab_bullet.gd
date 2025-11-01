extends EnemyCharacter

signal returned
signal hit_player

@export var speed: float = 180.0
@export var max_range: float = 320.0
@export var spike_damage: int = 1

var origin: Vector2
var target_corner: Vector2
var going_out := true
var owner_crab: Node = null
var traveled := 0.0
var dir: Vector2 = Vector2.RIGHT

func launch(_owner: Node, _origin: Vector2, _target: Vector2) -> void:
	owner_crab = _owner
	origin = _origin
	global_position = _origin
	target_corner = _target
	dir = (target_corner - origin).normalized()
	velocity = dir * speed
	if owner_crab and owner_crab.has_method("on_claw_launched"):
		owner_crab.on_claw_launched(origin)

func _physics_process(delta: float) -> void:
	if going_out:
		var step = speed * delta
		traveled += step
		velocity = dir * speed
		move_and_slide()
		if traveled >= max_range or global_position.distance_to(origin) >= max_range:
			# quay đầu về
			going_out = false
			dir = (origin - global_position).normalized()
			velocity = dir * speed
	else:
		velocity = dir * speed
		move_and_slide()
		if global_position.distance_to(origin) <= 6.0:
			if owner_crab and owner_crab.has_method("on_claw_returned"):
				owner_crab.on_claw_returned()
			emit_signal("returned")
			queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		emit_signal("hit_player")
		# gây damage spike tuỳ cơ chế game của bạn (ví dụ phát sự kiện lên HurtArea2D của player)
