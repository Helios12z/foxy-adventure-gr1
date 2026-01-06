extends WaterPrietestState

var _emergency_recovery_attempted: bool = false

func _enter() -> void:
	obj.change_animation("fall")
	_emergency_recovery_attempted = false

func _update(delta: float) -> void:
	# Only attempt emergency recovery in phase 2
	if obj.in_phase2 and not _emergency_recovery_attempted:
		if _should_emergency_recover():
			_attempt_emergency_recovery()
			_emergency_recovery_attempted = true

	control_fall_update(delta)

func _should_emergency_recover() -> bool:
	# Find the lowest floating platform Y position
	var lowest_platform_y := _get_lowest_platform_y()

	# Only recover if boss is below the lowest floating platform
	if obj.global_position.y > lowest_platform_y:
		return true

	return false

func _get_lowest_platform_y() -> float:
	var lowest_y := INF

	# Check all active jump markers to find the lowest platform
	for marker in obj.jump_markers:
		if marker and marker.is_active:
			var platform_y = marker.global_position.y
			if platform_y < lowest_y:
				lowest_y = platform_y

	# If no active markers, use a default threshold
	if lowest_y == INF:
		lowest_y = 600.0  # Default threshold

	return lowest_y

func _attempt_emergency_recovery() -> void:
	# Try to find nearest platform to jump to
	var nearest_marker = obj.get_nearest_jump_marker()

	if not nearest_marker:
		return

	# Only jump if cooldown allows
	if obj.state_transition_cooldown <= 0:
		obj.state_transition_cooldown = 0.5
		change_state(fsm.states.jumpstate)
