extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("roll")
	control_roll_enter()

func _update(delta: float) -> void:
	control_roll_update(delta)

func _exit() -> void:
	control_roll_exit()

func has_invincibility() -> bool:
	return has_roll_invincibility()
