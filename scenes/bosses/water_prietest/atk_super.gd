extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("atk_super")
	do_atk_super()
