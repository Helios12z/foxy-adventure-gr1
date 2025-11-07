extends EnemyState

func _enter() -> void:
	obj.change_animation("idle") 
	timer = obj.fatigue_duration()

func _update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		change_state(fsm.states.idle)
