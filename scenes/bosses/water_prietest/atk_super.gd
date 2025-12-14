extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("atk_super")
	obj.velocity.x = 0.0
	do_atk_super()
