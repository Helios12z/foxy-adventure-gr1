extends EnemyState

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta):
	obj.velocity.x = obj.direction * 50
	if obj.can_detect_player():
		change_state(fsm.states.chase)
	if _should_turn_around():
		obj.turn_around()


func _should_turn_around() -> bool:
	if obj.is_touch_wall():
		return true
	if obj.is_on_floor() and obj.is_can_fall():
		return true
	return false
