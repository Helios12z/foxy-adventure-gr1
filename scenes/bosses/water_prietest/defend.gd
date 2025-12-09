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

func should_block_damage(_attack_direction: Vector2) -> bool:
	if not _is_blocking:
		return false

	var player = obj.get_player()
	if player == null:
		return false

	# boss đang nhìn chiều nào
	var facing_dir := 1 if not obj.animated_sprite_2d.flip_h else -1
	# hướng từ boss tới player
	var attack_dir = sign(player.global_position.x - obj.global_position.x)

	return attack_dir == facing_dir

func check_and_block_attack(hit_area: HitArea2D) -> bool:
	if not _is_blocking:
		return false

	var facing_dir := 1 if not obj.animated_sprite_2d.flip_h else -1
	var attack_dir := 0

	if hit_area:
		attack_dir = sign(hit_area.global_position.x - obj.global_position.x)

	return attack_dir == facing_dir

func _exit() -> void:
	_is_blocking = false
	obj.velocity.x = 0.0
