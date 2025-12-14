extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("fall")

func _update(delta: float) -> void:
	control_fall_update(delta)
