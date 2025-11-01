extends EnemyState

@export var hurt_timer: float = 0.5
@export var knockback_force: float = 150.0
@export var friction: float = 600.0

var elapsed_time: float = 0.0
var knock_dir: int = 1

func _enter() -> void:
	if obj.has_method("change_animation"):
		obj.change_animation("hurt")
	if "can_control" in obj:
		obj.can_control = false
	# Lấy hướng hất theo trục X từ knockback_direction
	var facing := int(sign(obj.direction)) if ("direction" in obj) else 1
	var xdir = obj.knockback_direction.x
	if abs(xdir) >= 0.001:
		knock_dir = int(sign(xdir))
	else:
		# nếu vector không có phương ngang rõ ràng -> hất lùi so với hướng đang quay mặt
		knock_dir = -facing
	# chỉ hất theo X, không đội nhân vật lên
	obj.velocity.x = knockback_force * knock_dir
	elapsed_time = 0.0

func _update(delta: float) -> void:
	elapsed_time += delta

	# ma sát để dừng dần
	if abs(obj.velocity.x) > 0.0:
		obj.velocity.x = move_toward(obj.velocity.x, 0.0, friction * delta)

	# gravity nhẹ để bám đất
	obj.velocity.y += obj.gravity * delta
	obj.move_and_slide()

	if elapsed_time >= hurt_timer:
		_recover_from_hurt()

func _recover_from_hurt() -> void:
	if "can_control" in obj:
		obj.can_control = true
	if fsm.states.has("idle"):
		fsm.change_state(fsm.states.idle)
	elif fsm.states.has("walk"):
		fsm.change_state(fsm.states.walk)
