extends EnemyState

func _enter() -> void:
	obj.change_animation("atk2_stop")
	timer = obj.fatigue_after_atk2 # 2.0s

func _update(d: float) -> void:
	if update_timer(d):
		change_state(fsm.states.walk)
