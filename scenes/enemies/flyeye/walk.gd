extends EnemyState

## Flying walk/patrol state for FlyEye
## Handles horizontal movement with vertical platform tracking

enum VerticalState {
	LEVEL,      # On same level as player
	FLYING_UP,  # Moving up to reach player
	FLYING_DOWN # Moving down to reach player
}

var vertical_state: VerticalState = VerticalState.LEVEL
@export var patrol_speed: float = 50.0


func _enter() -> void:
	obj.change_animation("walk")
	vertical_state = VerticalState.LEVEL

	# Only return home if we're not at home AND didn't just come from ReturnHome
	if obj.has_method("is_at_home") and not obj.is_at_home():
		if fsm.previous_state and fsm.previous_state.name.to_lower() != "returnhome":
			change_state(fsm.states.returnhome if fsm.states.has("returnhome") else fsm.states.walk)


func _update(delta: float) -> void:
	# Always check for player detection first
	if obj.can_detect_player():
		change_state(fsm.states.chase)
		return

	# Handle horizontal movement
	obj.velocity.x = obj.direction * patrol_speed

	# Check for patrol range limit - turn around if too far
	if obj.has_method("should_turn_for_patrol") and obj.should_turn_for_patrol():
		obj.turn_around()
		obj._check_changed_direction()
	# Check for wall and turn around
	elif obj.is_wall_ahead():
		obj.turn_around()
		obj._check_changed_direction()

	# Move
	obj.move_and_slide()


func _should_turn_around() -> bool:
	# Turn around at walls
	if obj.is_wall_ahead():
		return true

	# For flying enemies, we don't check for ledges/falling
	return false
