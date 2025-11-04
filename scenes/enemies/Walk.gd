extends EnemyState

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta):
	obj.velocity.x = obj.direction * 50
	if _should_turn_around():
		obj.turn_around()


func _should_turn_around() -> bool:
	if obj.is_touch_wall():
		print(obj.front_ray_cast.get_collider())
		return true
	if obj.is_on_floor() and obj.is_can_fall():
		return true
	return false
