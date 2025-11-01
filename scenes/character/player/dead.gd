extends PlayerState

func _enter() -> void:
	obj.change_animation("dead")
	# Gọi coroutine đợi 0.5s rồi reset scene
	obj.set_detect_and_hurt_collsion(false)
	obj.velocity.x = 0
	timer = 1

func _update(_delta: float) -> void:
	if update_timer(_delta):
			get_tree().reload_current_scene()
		
