extends WaterPrietestState

var _defend_timer: float = 0.0
var _is_blocking: bool = false

func _enter() -> void:
	obj.change_animation("defend")
	_defend_timer = 0.0
	_is_blocking = false
	obj.velocity.x = 0.0  # Stop movement while defending

func _update(delta: float) -> void:
	_defend_timer += delta

	# Windup phase before blocking
	if _defend_timer >= obj.defend_windup_time and not _is_blocking:
		_is_blocking = true
		# Enable invincibility from front direction

	# Check if defend duration is over
	if _defend_timer >= obj.defend_windup_time + obj.defend_duration:
		# Start cooldown and transition back to idle
		obj.start_defend_cooldown()
		change_state(fsm.states.idle)

func should_block_damage(damage: int, attack_direction: Vector2) -> bool:
	"""
	Returns true if damage should be blocked, false if damage should be applied
	"""
	if not _is_blocking:
		return false  # Not blocking yet

	# Check if attack is from front direction (can only block forward)
	var facing_dir = 1 if not obj.animated_sprite_2d.flip_h else -1
	var attack_dir = sign(attack_direction.x)

	# Block attacks from front (180 degree arc)
	if attack_dir == facing_dir or attack_dir == 0:
		# Play block effect/spark if needed
		return true  # Damage blocked
	else:
		return false  # Take damage from behind/sides

func _exit() -> void:
	_is_blocking = false
	obj.velocity.x = 0.0
