extends EnemyState

var follow_cooldown: float = 2.0   

var _was_touching_wall: bool = false
var _was_about_to_fall: bool = false

func _enter() -> void:
	obj.change_animation("walk")
	timer = follow_cooldown
	_was_touching_wall = obj.is_touch_wall()
	_was_about_to_fall = obj.is_on_floor() and obj.is_can_fall()


func _update(delta: float) -> void:
	var player_in_sight = obj.can_detect_player()

	if not player_in_sight:
		obj.velocity.x = move_toward(obj.velocity.x, 0.0, obj.move_speed * delta)
		fsm.change_state(fsm.states.idle)
		return

	var env_turn := _should_turn_around_once()
	if env_turn:
		obj.turn_around()
		obj.collision_shape_2d.position.x *= -1 

	obj.velocity.x = obj.direction * obj.move_speed

	if update_timer(delta):
		if player_in_sight:
			fsm.change_state(fsm.states.idle_atk)
		else:
			fsm.change_state(fsm.states.idle)


func _should_turn_around_once() -> bool:
	var touching_wall = obj.is_touch_wall()
	var about_to_fall = obj.is_on_floor() and obj.is_can_fall()

	var turn = (touching_wall and not _was_touching_wall) \
		or (about_to_fall and not _was_about_to_fall)

	_was_touching_wall = touching_wall
	_was_about_to_fall = about_to_fall

	return turn
