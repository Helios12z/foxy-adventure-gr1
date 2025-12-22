extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("surf")

func _update(delta: float) -> void:
	var p = obj.get_player()
	var attack_table = [
		[fsm.states.atk_1, 0.1],
		[fsm.states.atk_2, 0.4],
		[fsm.states.atk_3, 0.7],
		[fsm.states.atk_super, 0.95],
	]

	# If player is directly underneath, prioritize jump state to get better positioning
	if p and p.global_position.y < obj.global_position.y - 80:
		var horizontal_distance = abs(p.global_position.x - obj.global_position.x)
		if horizontal_distance <= 100 and obj.state_transition_cooldown <= 0:
			obj.state_transition_cooldown = 0.5
			change_state(fsm.states.jumpstate)
			return

	control_move(obj.surf_speed, attack_table, Callable(self, "_on_reach_target"), true)

func _on_reach_target(dy: float) -> void:
	# Only fall if not on floor
	if not obj.is_on_floor():
		change_state(fsm.states.fallstate)
