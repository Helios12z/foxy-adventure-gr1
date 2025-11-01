extends EnemyState

func _enter() -> void:
	obj.change_animation("atk1_recover")
	timer = 0.25

func _update(d: float) -> void:
	if update_timer(d):
		change_state(fsm.states.walk)
