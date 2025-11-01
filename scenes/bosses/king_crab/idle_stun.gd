extends EnemyState

func _enter() -> void:
	obj.change_animation("idle_stun")
	timer = 0.25

func _update(d: float) -> void:
	if update_timer(d):
		change_state(fsm.states.walk)
