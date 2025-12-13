extends WaterPrietestState

var _roll_start_x: float = 0.0
var _roll_start_y: float = 0.0
var _roll_target_x: float = 0.0
var _roll_total_time: float = 0.0
var _elapsed: float = 0.0

var _roll_direction: int = 1
var _has_invincibility: bool = false

const EXTRA_HEIGHT_MULT := 1.2       
const THROUGH_BOUND_RATIO := 0.6     
const THROUGH_PLAYER_OFFSET := 40.0 

func _enter() -> void:
	obj.change_animation("roll")
	_has_invincibility = true

	# Play roll sound
	if obj.roll:
		obj.roll.play()

	_roll_start_x = obj.global_position.x
	_roll_start_y = obj.global_position.y
	_elapsed = 0.0

	var player = obj.get_player()
	var has_player := player != null

	if has_player:
		if player.global_position.x < obj.global_position.x:
			_roll_direction = 1
		else:
			_roll_direction = -1
	else:
		_roll_direction = 1

	var lb: Rect2 = obj.level_bounds
	var margin := 8.0
	var has_bounds := lb.size.x > 0.0

	var left := 0.0
	var right := 0.0
	if has_bounds:
		left = lb.position.x + margin
		right = lb.position.x + lb.size.x - margin

	var desired_distance = obj.roll_distance 
	var away_target_x = _roll_start_x + float(_roll_direction) * desired_distance

	if has_bounds:
		away_target_x = clamp(away_target_x, left, right)

	var away_distance = abs(away_target_x - _roll_start_x)

	var use_roll_through := false

	if has_player and has_bounds:
		if away_distance < desired_distance * THROUGH_BOUND_RATIO:
			use_roll_through = true

	var final_target_x: float

	if use_roll_through:
		_roll_direction = sign(player.global_position.x - _roll_start_x)
		if _roll_direction == 0:
			_roll_direction = 1

		final_target_x = player.global_position.x + float(_roll_direction) * THROUGH_PLAYER_OFFSET

		if has_bounds:
			final_target_x = clamp(final_target_x, left, right)
	else:
		final_target_x = away_target_x

	_roll_target_x = final_target_x

	var distance = abs(_roll_target_x - _roll_start_x)
	if distance < 4.0:
		distance = 4.0

	var speed = max(obj.roll_speed, 1.0)

	_roll_total_time = distance / speed
	_roll_total_time = max(_roll_total_time, 0.35)

	var g := obj.get_gravity().y

	var vy0 := -0.5 * g * _roll_total_time * EXTRA_HEIGHT_MULT

	obj.velocity.x = _roll_direction * speed
	obj.velocity.y = vy0

	obj.change_direction(_roll_direction)


func _update(delta: float) -> void:
	_elapsed += delta

	obj.velocity.x = _roll_direction * obj.roll_speed

	obj.velocity.y += obj.get_gravity().y * delta

	var lb: Rect2 = obj.level_bounds
	if lb.size.x > 0.0:
		var margin := 4.0
		var left := lb.position.x + margin
		var right := lb.position.x + lb.size.x - margin
		var pos := obj.global_position
		pos.x = clamp(pos.x, left, right)
		obj.global_position = pos

	var done_time := _elapsed >= _roll_total_time * 0.9
	var landed := obj.is_on_floor() and _elapsed > 0.1

	var sprite: AnimatedSprite2D = obj.animated_sprite_2d
	var anim_done := false

	if sprite and sprite.animation == "roll":
		if not sprite.is_playing():
			anim_done = true

	if done_time and landed and anim_done:
		_finish_roll()
		return

func _finish_roll() -> void:
	_has_invincibility = false
	obj.velocity.x = 0.0
	change_state(fsm.states.idle)


func _about_to_fall_off_edge() -> bool:
	var ray_length := 50.0
	var ray_direction := Vector2(_roll_direction, 1.0).normalized()
	var ray_start := obj.global_position + Vector2(_roll_direction * 30.0, 0.0)
	var ray_end := ray_start + ray_direction * ray_length

	var space_state := obj.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [obj]
	query.collision_mask = 1

	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _exit() -> void:
	_has_invincibility = false
	obj.velocity.x = 0.0


func has_invincibility() -> bool:
	return _has_invincibility
