extends WaterPrietestState

@export var roll_speed: float = 200.0
@export var roll_distance: float = 150.0

var _roll_start_x: float = 0.0
var _roll_direction: int = 1
var _has_invincibility: bool = false

func _enter() -> void:
	obj.change_animation("roll")
	_has_invincibility = true
	_roll_start_x = obj.global_position.x

	# Determine roll direction - roll away from player
	var player = obj.get_player()
	if player:
		_roll_direction = -1 if player.global_position.x < obj.global_position.x else 1
	else:
		_roll_direction = 1  # Default roll right

	# Set roll velocity
	obj.velocity.x = _roll_direction * roll_speed
	obj.velocity.y = 0  # Don't roll while falling/jumping

	# Make boss face the rolling direction
	obj.change_direction(_roll_direction)

func _update(delta: float) -> void:
	# Calculate how far we've rolled
	var distance_rolled = abs(obj.global_position.x - _roll_start_x)

	# Check if we've rolled the desired distance or about to fall off edge
	if distance_rolled >= roll_distance or _about_to_fall_off_edge():
		# Stop rolling and transition to idle
		obj.velocity.x = 0.0
		_has_invincibility = false
		change_state(fsm.states.idle)
		return

	# Maintain roll velocity
	obj.velocity.x = _roll_direction * roll_speed

	# Apply gravity if not on ground
	if not obj.is_on_floor():
		obj.velocity.y += obj.get_gravity().y * delta

func _about_to_fall_off_edge() -> bool:
	# Cast a ray downward to check for ground ahead
	var ray_length = 50.0
	var ray_direction = Vector2(_roll_direction, 1).normalized()
	var ray_start = obj.global_position + Vector2(_roll_direction * 30, 0)

	# Simple edge detection - check if there's no ground ahead
	var space_state = obj.get_world_2d().direct_space_state

	# Use the oldest Godot syntax - create a dictionary with parameters
	var ray_params = {
		"from": ray_start,
		"to": ray_start + ray_direction * ray_length,
		"exclude": [obj],
		"collision_mask": 1
	}

	var result = space_state.intersect_ray(ray_params)
	return result.empty()

func _exit() -> void:
	_has_invincibility = false
	obj.velocity.x = 0.0

# Check for invincibility (called from main boss script)
func has_invincibility() -> bool:
	return _has_invincibility
