extends EnemyState

func _enter() -> void:
	obj.change_animation("idle_atk")

func _update(delta: float) -> void:
	if obj.claw_returned:
		change_state(fsm.states.idle_stun)
