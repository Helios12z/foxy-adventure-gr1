extends EnemyState

var returning_to_fight: bool = false
var retreat_start_position: Vector2
var retreat_direction: int = 1  # Direction chosen for retreat (left or right)
const RETREAT_DISTANCE: float = 500.0  # Distance to run before spawning reinforcements
var cached_goblin_scene: PackedScene = null  # Cache loaded scene

func _enter() -> void:
	obj.change_animation("walk")
	returning_to_fight = false

	# Store starting position
	retreat_start_position = obj.global_position
	print("Goblin entered retreat at position: ", retreat_start_position)
	print("Has already summoned reinforcements: ", obj.has_summoned_reinforcements)

	# Determine best retreat direction (left or right)
	_determine_retreat_direction()
	print("Retreat direction chosen: ", retreat_direction)

func _update(delta: float) -> void:
	if returning_to_fight:
		_return_and_fight()
		return

	# Run away from player
	_run_away_from_player()

	# Check if traveled far enough to spawn reinforcements (only if haven't spawned before)
	if not obj.has_summoned_reinforcements:
		var distance = abs(obj.global_position.x - retreat_start_position.x)
		if distance >= RETREAT_DISTANCE:
			print("Traveled ", distance, " pixels, spawning reinforcements!")
			_spawn_reinforcements()
			obj.has_summoned_reinforcements = true  # Mark as spawned (persistent)
			returning_to_fight = true
	else:
		# Already spawned reinforcements before, just return to fight
		print("Already spawned reinforcements before, returning to fight directly")
		returning_to_fight = true

# Determine best retreat direction (left or right based on available space)
func _determine_retreat_direction() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		retreat_direction = 1
		return

	# Calculate direction away from player
	var direction_away = sign(obj.global_position.x - player.global_position.x)
	if direction_away == 0:
		direction_away = 1

	# Check if there's space in that direction (cast ray)
	var has_space_ahead = _check_space_in_direction(direction_away)
	var has_space_behind = _check_space_in_direction(-direction_away)

	# Choose direction with more space
	if has_space_ahead:
		retreat_direction = direction_away
	elif has_space_behind:
		# If no space ahead but space behind, go toward player (will pass through)
		retreat_direction = -direction_away
	else:
		# No space in either direction, just run away from player
		retreat_direction = direction_away

# Check if there's space in a given direction (simple distance check)
func _check_space_in_direction(direction: int) -> bool:
	var check_distance = 300
	# Use raycast to check for walls
	var space_query = PhysicsRayQueryParameters2D.new()
	space_query.from = obj.global_position
	space_query.to = obj.global_position + Vector2(direction * check_distance, 0)
	space_query.collision_mask = 1  # Default collision mask (adjust if needed)

	var result = obj.get_world_2d().direct_space_state.intersect_ray(space_query)
	return result.is_empty()  # Empty means no obstacle, so there's space

# Run away from the player
func _run_away_from_player() -> void:
	# Update facing direction
	obj.change_direction(retreat_direction)

	# Check if we should turn around (wall or canyon)
	if _should_turn_for_obstacle():
		# Turn around and move opposite direction
		retreat_direction = -retreat_direction
		obj.change_direction(retreat_direction)

	# Run in chosen direction
	obj.velocity.x = retreat_direction * obj.retreat_speed

	# Debug: Print distance every 100 pixels
	var distance = abs(obj.global_position.x - retreat_start_position.x)
	if int(distance) % 100 == 0 and distance > 0:
		print("Distance traveled: ", distance, "/", RETREAT_DISTANCE)

# Check if goblin has traveled far enough from start position
func _has_traveled_far_enough() -> bool:
	var distance_traveled = abs(obj.global_position.x - retreat_start_position.x)
	return distance_traveled >= RETREAT_DISTANCE

# Return to fight
func _return_and_fight() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		# No player, go back to patrol at spawn position
		_return_to_spawn()
		return

	# Check if player is detected
	if not obj.can_detect_player():
		# Player out of sight, return to spawn position and patrol
		_return_to_spawn()
		return

	# Player detected, move toward player
	var direction_to_player = sign(player.global_position.x - obj.global_position.x)
	if direction_to_player == 0:
		direction_to_player = 1

	# Update facing direction
	obj.change_direction(direction_to_player)

	# Check for obstacles
	if _should_turn_for_obstacle():
		direction_to_player = -direction_to_player
		obj.change_direction(direction_to_player)

	# Move toward player
	obj.velocity.x = direction_to_player * (obj.retreat_speed * 0.8)

	# If close enough, start fighting
	var distance_to_player = obj.global_position.distance_to(player.global_position)
	if distance_to_player < 200:
		# Close enough to fight
		if obj.is_in_attack_scope():
			change_state(fsm.states.attack)
		else:
			change_state(fsm.states.chase)

# Return to spawn position for patrol
func _return_to_spawn() -> void:
	var spawn_position = obj.get_spawn_position()
	var distance_to_spawn = obj.global_position.distance_to(spawn_position)

	# Check if at spawn position
	if distance_to_spawn < 20:
		# Back at spawn, go to patrol mode
		change_state(fsm.states.walk)
		return

	# Move toward spawn position
	var direction_to_spawn = sign(spawn_position.x - obj.global_position.x)
	if direction_to_spawn == 0:
		direction_to_spawn = 1

	# Update facing direction
	obj.change_direction(direction_to_spawn)

	# Check for obstacles
	if _should_turn_for_obstacle():
		direction_to_spawn = -direction_to_spawn
		obj.change_direction(direction_to_spawn)

	# Move toward spawn position
	obj.velocity.x = direction_to_spawn * 100

# Spawn reinforcement goblins
func _spawn_reinforcements() -> void:
	print("Attempting to spawn reinforcements...")

	# Get the goblin scene - use export if set, otherwise load dynamically
	var goblin_scene_to_use = obj.goblin_scene
	if goblin_scene_to_use == null:
		print("goblin_scene export is null, loading dynamically...")
		if cached_goblin_scene == null:
			cached_goblin_scene = load("res://scenes/enemies/goblin/goblin.tscn")
		goblin_scene_to_use = cached_goblin_scene

	if goblin_scene_to_use == null:
		push_error("Failed to load goblin scene!")
		return

	# Spawn 2 new goblins near the current goblin
	for i in range(2):
		var new_goblin = goblin_scene_to_use.instantiate()
		# Spawn offset: one slightly above, one slightly below
		var spawn_offset = Vector2(0, -30 if i == 0 else 30)

		# Add to the same parent as the current goblin
		var parent = obj.get_parent()
		parent.add_child(new_goblin)
		new_goblin.global_position = obj.global_position + spawn_offset

		# Set health to full
		new_goblin.health = new_goblin.max_health

		# Prevent spawned goblins from retreating/spawning more goblins
		new_goblin.can_retreat = false

		# Make spawned goblins run in the same direction as original
		new_goblin.velocity.x = retreat_direction * obj.retreat_speed
		new_goblin.change_direction(retreat_direction)

		print("Successfully spawned reinforcement goblin ", (i + 1), " at: ", new_goblin.global_position, " moving in direction: ", retreat_direction)

	print("Finished spawning reinforcements")

# Check if should turn around (wall or fall ahead)
func _should_turn_for_obstacle() -> bool:
	# Check for wall ahead
	if obj.is_touch_wall():
		return true

	# Check for fall ahead
	if obj.is_on_floor() and obj.is_can_fall():
		return true

	return false
