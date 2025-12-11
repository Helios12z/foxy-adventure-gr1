extends WaterPrietestState

var _is_blocking: bool = false

func _enter() -> void:
	_is_blocking = true
	obj.velocity.x = 0.0
	obj.change_animation("defend")

func _update(delta: float) -> void:
	if not _is_blocking:
		return

	var sprite: AnimatedSprite2D = obj.animated_sprite_2d

	if sprite.animation != "defend":
		return

	if not sprite.is_playing():
		_is_blocking = false
		obj.start_defend_cooldown()
		change_state(fsm.states.idle)

func should_block_damage(_attack_direction: Vector2) -> bool:
	if not _is_blocking:
		return false

	var player = obj.get_player()
	if player == null:
		return false

	var facing_dir := 1 if not obj.animated_sprite_2d.flip_h else -1
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
