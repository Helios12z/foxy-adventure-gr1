extends WaterPrietestState

var timeout = 3.0

func _enter() -> void:
	obj.change_animation("atk_super")
	do_atk_super()
	timer = timeout

func _update( _delta ):
	if update_timer(_delta): change_state(fsm.states.surf)
