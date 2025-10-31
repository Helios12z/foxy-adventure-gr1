extends PlayerState

func _enter() -> void:
	obj.change_animation("dead")
	# Gọi coroutine đợi 0.5s rồi reset scene
	obj.velocity.x = 0
	_reset_scene_after_delay()

func _update(_delta: float) -> void:
	pass

# ✅ Hàm riêng xử lý reset sau 0.5s
func _reset_scene_after_delay() -> void:
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()
