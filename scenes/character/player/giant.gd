extends PlayerState


func _enter() -> void:
	obj.activate_giant_form()
	timer = 0.5  # Đợi animation transform

func _update(_delta: float) -> void:
	# Chờ animation transform hoàn tất
	if update_timer(_delta):
		# Transform xong, chuyển về idle
		change_state(fsm.states.idle)
