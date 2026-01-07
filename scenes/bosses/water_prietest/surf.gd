extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("surf")

func _update(delta: float) -> void:
	var p = obj.get_player()
	var attack_table = [
		[fsm.states.atk_1, 0.1],
		[fsm.states.atk_super, 0.4],
		[fsm.states.atk_3, 0.7],
		[fsm.states.atk_2, 0.95],
	]

	# Check if boss is about to fall off and needs to jump to safety
	if obj.in_phase2 and _should_jump_to_safety():
		if obj.state_transition_cooldown <= 0:
			obj.state_transition_cooldown = 1.0
			change_state(fsm.states.jumpstate)
			return

	# If player is directly underneath, prioritize jump state to get better positioning
	if p and p.global_position.y < obj.global_position.y - 80:
		var horizontal_distance = abs(p.global_position.x - obj.global_position.x)
		if horizontal_distance <= 100 and obj.state_transition_cooldown <= 0:
			obj.state_transition_cooldown = 0.5
			change_state(fsm.states.jumpstate)
			return

	control_move(obj.surf_speed, attack_table, Callable(self, "_on_reach_target"), true)

func _should_jump_to_safety() -> bool:
	# Check if boss is near an edge and about to fall
	if not obj.is_on_floor():
		return false

	var current_marker = obj._boss_marker()
	if not current_marker:
		return false

	# Check if there's a safe platform below
	var below_pos = obj.global_position + Vector2(0, 100)
	var below_marker = obj._marker_for_pos(below_pos)

	# If no platform below and we have floating platforms available, jump to safety
	if not below_marker and obj.jump_markers.size() > 0:
		# Find nearest platform marker
		var nearest_marker = obj.get_nearest_jump_marker()
		if nearest_marker and nearest_marker != current_marker:
			return true

	return false

func _on_reach_target(dy: float) -> void:
	# Only fall if not on floor
	if not obj.is_on_floor():
		change_state(fsm.states.fallstate)
