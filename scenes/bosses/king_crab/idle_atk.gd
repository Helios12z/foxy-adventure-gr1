extends EnemyState

func _enter() -> void:
	obj.change_animation("idle_atk")

func _update(delta: float) -> void:
	if obj.control_claw_out_and_back(delta):
		change_state(fsm.states.atk1_recover)
