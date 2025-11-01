extends EnemyState

func _enter() -> void:
	obj.change_animation("atk1_windup")
	timer = 0.2

func _update(d: float) -> void:
	if update_timer(d):
		change_state(fsm.states.atk1_fire)
