extends EnemyState

var flee_direction: int = 1  # Direction to run away from player
var returning_to_spawn: bool = false  # True when returning to spawn position
var spawn_position: Vector2  # Cached spawn position

func _enter() -> void:
	obj.change_animation("walk")
	# Cache spawn position
	spawn_position = obj.get_spawn_position()
	returning_to_spawn = false
	_determine_flee_direction()

func _update(delta: float) -> void:
	# Recover health over time
	if obj.health < obj.max_health:
		obj.health += obj.health_recovery_rate * delta
		if obj.health > obj.max_health:
			obj.health = obj.max_health

	# Check if health is fully recovered
	if obj.health >= obj.max_health:
		# Health full, return to spawn if not already there
		if not returning_to_spawn:
			returning_to_spawn = true
		_return_to_spawn()
		return

	# Health still recovering, run away from player
	returning_to_spawn = false
	_run_away_from_player()

# Run away from the player
func _run_away_from_player() -> void:
	# Determine which direction is away from player
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		# No player, just wander
		obj.velocity.x = obj.direction * 50
		return

	# Calculate direction away from player
	var direction_away = sign(obj.global_position.x - player.global_position.x)
	if direction_away == 0:
		direction_away = 1  # Default to right if aligned

	# Check if we should turn around (wall or canyon)
	if _should_turn_for_obstacle(direction_away):
		obj.turn_around()
		direction_away = -direction_away

	# Run in that direction
	obj.velocity.x = direction_away * obj.retreat_speed
	obj.change_direction(direction_away)  # Face the direction of movement

# Return to spawn position
func _return_to_spawn() -> void:
	var distance_to_spawn = obj.global_position.distance_to(spawn_position)

	# Check if we're at spawn position
	if distance_to_spawn < 10:
		# Back at spawn, check if player detected
		if obj.can_detect_player():
			if obj.is_in_attack_scope():
				change_state(fsm.states.attack)
			else:
				change_state(fsm.states.chase)
		else:
			change_state(fsm.states.walk)
		return

	# Move toward spawn position
	var direction_to_spawn = sign(spawn_position.x - obj.global_position.x)
	if direction_to_spawn == 0:
		direction_to_spawn = 1

	# Check if should turn around (avoid obstacles)
	if _should_turn_for_obstacle(direction_to_spawn):
		obj.turn_around()
		direction_to_spawn = -direction_to_spawn

	# Move toward spawn (slower when returning)
	obj.velocity.x = direction_to_spawn * 100
	obj.change_direction(direction_to_spawn)  # Face the direction of movement

# Determine initial flee direction
func _determine_flee_direction() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player != null:
		var direction_away = sign(obj.global_position.x - player.global_position.x)
		if direction_away != 0:
			flee_direction = direction_away

# Check if should turn around (wall or fall ahead)
func _should_turn_for_obstacle(movement_direction: int) -> bool:
	# Check for wall in movement direction
	if movement_direction > 0 and obj.is_touch_wall():
		return true
	if movement_direction < 0 and obj.is_touch_wall():
		return true

	# Check for fall ahead
	if obj.is_on_floor() and obj.is_can_fall():
		return true

	return false
