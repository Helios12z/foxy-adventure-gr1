extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("atk_3")
	obj.velocity.x = 0.0
	do_atk3()
