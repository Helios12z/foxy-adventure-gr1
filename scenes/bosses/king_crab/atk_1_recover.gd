extends EnemyState
func _enter() -> void:
	timer=0.25
	obj.change_animation("atk1_recover")

func _update(d: float) -> void:
	if update_timer(d):
		change_state(fsm.states.walk)
