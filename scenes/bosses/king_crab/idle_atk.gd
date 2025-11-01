extends EnemyState

func _enter() -> void:
	obj.change_animation("idle_atk")

func _update(delta: float) -> void:
	# bullet đã phát "returned" → obj.claw_returned = true
	if obj.claw_returned:
		change_state(fsm.states.atk1_recover)
