extends EnemyState

var retreat_direction: int = 1  # Direction to run away (1 = right, -1 = left)
var safety_threshold: float = 80.0  # Distance to be considered "near" other goblins
const SAFETY_COOLDOWN_TIME: float = 3.0  # Seconds to stay with allies before retreating again

func _enter() -> void:
	obj.change_animation("walk")
	# Force update nearby goblins when entering retreat state
	obj._update_nearby_goblins()
	_determine_retreat_direction()

func _update(delta: float) -> void:
	# Check if health is restored or no more goblins - return to fight
	if not obj.should_retreat() or not obj.is_near_goblin():
		# Health is back above 50% or no goblins left, stop retreating
		if obj.can_detect_player():
			if obj.is_in_attack_scope():
				change_state(fsm.states.attack)
			else:
				change_state(fsm.states.chase)
		else:
			change_state(fsm.states.walk)
		return

	# Update retreat direction periodically (in case goblins moved)
	_determine_retreat_direction()

	# Run away in the calculated direction
	obj.velocity.x = retreat_direction * obj.retreat_speed
	obj.change_direction(retreat_direction)

	# Check if reached safety (near other goblins)
	if _is_near_other_goblins():
		# Reached safety, set cooldown so we don't immediately retreat again
		obj.retreat_safety_cooldown = SAFETY_COOLDOWN_TIME
		# Go back to fight
		if obj.can_detect_player():
			if obj.is_in_attack_scope():
				change_state(fsm.states.attack)
			else:
				change_state(fsm.states.chase)
		else:
			change_state(fsm.states.walk)

# Determine which direction to run (toward where goblins are)
func _determine_retreat_direction() -> void:
	if obj.nearby_goblins.is_empty():
		retreat_direction = -obj.direction  # Run opposite to current facing if no goblins
		return

	# Calculate the center point of all nearby goblins
	var goblins_center = Vector2.ZERO
	for goblin in obj.nearby_goblins:
		goblins_center += goblin.global_position
	goblins_center /= obj.nearby_goblins.size()

	# Run in the direction where goblins are located
	var direction_vector = goblins_center - obj.global_position
	var direction_to_goblins = sign(direction_vector.x)

	# If sign returns 0 (very close alignment), use the full direction vector
	if direction_to_goblins == 0:
		direction_to_goblins = 1 if direction_vector.x >= 0 else -1

	retreat_direction = direction_to_goblins

# Check if close enough to other goblins
func _is_near_other_goblins() -> bool:
	for goblin in obj.nearby_goblins:
		if obj.global_position.distance_to(goblin.global_position) < safety_threshold:
			return true
	return false
