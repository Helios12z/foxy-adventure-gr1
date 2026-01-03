extends EnemyState

## Flying chase state for FlyEye
## Chases player horizontally and vertically

@export var chase_speed: float = 80.0
@export var vertical_speed: float = 100.0
@export var vertical_threshold: float = 15.0  # Distance to consider "on same level"

enum VerticalState {
	LEVEL,
	FLYING_UP,
	FLYING_DOWN
}

var vertical_state: VerticalState = VerticalState.LEVEL
var player: Player = null


func _enter() -> void:
	obj.change_animation("walk")
	vertical_state = VerticalState.LEVEL
	# Get player reference from fly_eye
	player = obj.get("player") as Player


func _update(delta: float) -> void:
	# Check if still detecting player
	if not obj.can_detect_player():
		# Return to home position instead of just walking
		print("[Chase] Player lost, returning home")
		if fsm.states.has("return_home"):
			print("[Chase] Transitioning to ReturnHome state")
			change_state(fsm.states.return_home)
		else:
			print("[Chase] No ReturnHome state, going to Walk")
			change_state(fsm.states.walk)
		return

	# Check if in attack range
	if obj.is_in_attack_scope():
		# Stop moving before attacking
		obj.velocity = Vector2.ZERO
		change_state(fsm.states.attack)
		return

	# Refresh player reference
	player = obj.get("player") as Player
	if not player or not is_instance_valid(player):
		# Lost player reference, return to patrol
		change_state(fsm.states.walk)
		return

	var y_diff = player.global_position.y - obj.global_position.y

	# Determine vertical state
	if abs(y_diff) < vertical_threshold:
		# On same level, just move horizontally
		vertical_state = VerticalState.LEVEL
		obj.velocity.y = 0
	elif y_diff > 0:
		# Player is below
		vertical_state = VerticalState.FLYING_DOWN
		obj.velocity.y = vertical_speed
	else:
		# Player is above
		vertical_state = VerticalState.FLYING_UP
		obj.velocity.y = -vertical_speed

	# Horizontal movement towards player
	var x_diff = player.global_position.x - obj.global_position.x
	if x_diff > 0:
		# Player to the right
		if obj.direction != 1:
			obj.change_direction(1)  # Use change_direction instead
		obj.velocity.x = chase_speed
	else:
		# Player to the left
		if obj.direction != -1:
			obj.change_direction(-1)  # Use change_direction instead
		obj.velocity.x = -chase_speed

	# Check for wall ahead and handle it
	if obj.has_method("is_wall_ahead") and obj.is_wall_ahead():
		# If there's a wall, stop horizontal movement but continue vertical
		obj.velocity.x = 0

	# Move
	obj.move_and_slide()
