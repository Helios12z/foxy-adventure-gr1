extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("atk_1")
	do_atk1()
