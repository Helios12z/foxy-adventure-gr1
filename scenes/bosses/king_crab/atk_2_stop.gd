extends KingCrabState

func _enter() -> void:
	obj.change_animation("atk2_stop")
	obj.velocity.x=0.0
	timer=1.25

func _update(delta: float) -> void:
	if update_timer(delta):  
		if obj.in_phase2:
			obj._chain_after_basic = true
		change_state(fsm.states.walk)

func _exit()->void:
	if obj.in_phase2: obj._chain_after_basic = true
