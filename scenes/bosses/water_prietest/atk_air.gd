extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("atk_air")
	obj.velocity.y += 50.0
	do_atk_air()
