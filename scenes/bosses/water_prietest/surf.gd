extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("surf")

func _update(delta: float) -> void:
	var attack_table = [
		[fsm.states.atk_1, 0.1],
		[fsm.states.atk_2, 0.4],
		[fsm.states.atk_3, 0.7],
		[fsm.states.atk_super, 0.95],
	]
	control_move(obj.surf_speed, attack_table, Callable(self, "_on_reach_target"), true)

func _on_reach_target(dy: float) -> void:
	# Only fall if not on floor
	if not obj.is_on_floor():
		change_state(fsm.states.fallstate)
