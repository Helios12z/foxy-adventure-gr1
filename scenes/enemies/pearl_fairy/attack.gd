extends EnemyState

@export var bullet_speed: float = 380.0

func _enter() -> void:
	obj.change_animation("attack")
	var frames := obj.animated_sprite.sprite_frames.get_frame_count("attack")
	var speed := obj.animated_sprite.sprite_frames.get_animation_speed("attack")
	timer = float(frames) / max(1.0, float(speed))

func _update(delta: float) -> void:
	if update_timer(delta):
		_spawn_bullets()
		obj.attack_cooldown_timer = 5.0
		change_state(fsm.states.move)

func _spawn_bullets() -> void:
	if not obj.has_node("Node2DFactory"):
		return
	var factory: Node2DFactory = obj.get_node("Node2DFactory")
	var origin := factory.global_position
	var dir := Vector2.RIGHT * obj.direction
	if obj.found_player != null:
		dir = (obj.found_player.global_position - origin).normalized()
	var main := factory.create()
	var left := factory.create()
	var right := factory.create()
	var dir_l := dir.rotated(deg_to_rad(30))
	var dir_r := dir.rotated(deg_to_rad(-30))
	_set_bullet_velocity(main, dir * bullet_speed)
	_set_bullet_velocity(left, dir_l * bullet_speed)
	_set_bullet_velocity(right, dir_r * bullet_speed)

func _set_bullet_velocity(b: Node2D, v: Vector2) -> void:
	if b is RigidBody2D:
		var rb := b as RigidBody2D
		rb.gravity_scale = 0.0
		rb.linear_damp = 0.0
		rb.angular_damp = 0.0
		rb.can_sleep = false
		rb.sleeping = false
		rb.freeze = false
		rb.linear_velocity = v
		rb.rotation = v.angle()
