extends EnemyState

var target_x: float

func _enter() -> void:
	obj.change_animation("atk2_roll")
	# ưu tiên lăn về phía player; nếu không có, lăn tới mép
	var player = (obj.has_method("get_target") and obj.get_target()) if obj.has_method("get_target") else null
	if player:
		target_x = clamp(player.global_position.x, obj.arena_min_x, obj.arena_max_x)
		obj.control_face_towards_x(target_x)
	else:
		target_x = obj.roll_target_x()

func _update(d: float) -> void:
	if obj.control_move_towards_x(target_x, obj.move_speed, d, false):
		change_state(fsm.states.atk2_stop)
		return
	var at_left  = obj.global_position.x <= obj.arena_min_x + 0.5
	var at_right = obj.global_position.x >= obj.arena_max_x - 0.5
	if at_left or at_right:
		change_state(fsm.states.atk2_stop)
