extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta: float) -> void:
	var attack_table = [
		[fsm.states.atk_1, 0.5],
		[fsm.states.atk_2, 0.5],
	]
	control_move(obj.move_speed, attack_table, Callable(self, "_on_reach_target"), true)

func _on_reach_target(dy: float) -> void:
	if dy > 0.0:
		change_state(fsm.states.fallstate)
	else:
		change_state(fsm.states.jumpstate)
