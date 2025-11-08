extends EnemyState
func _enter() -> void:
	timer=0.25
	obj.change_animation("atk1_recover")

func _update(d: float) -> void:
	if update_timer(d):
		if obj.in_phase2:
			obj._chain_after_basic = true
		change_state(fsm.states.walk)
