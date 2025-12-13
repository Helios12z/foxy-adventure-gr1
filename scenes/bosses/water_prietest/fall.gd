extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("fall")

func _update(delta: float) -> void:
	if obj.velocity.y > obj.max_fall_speed:
		obj.velocity.y = obj.max_fall_speed

	if obj.in_phase2:
		_check_air_attack_opportunity()

	_adjust_fall_horizontal_movement()

	if obj.is_on_floor():
		obj.velocity.x = 0.0
		_update_current_jump_marker()
		change_state(fsm.states.idle)

func _check_air_attack_opportunity() -> void:
	var player = obj.get_player()
	if not player:
		return

	var distance = obj.global_position.distance_to(player.global_position)
	var vertical_diff = abs(obj.global_position.y - player.global_position.y)

	if distance <= 150.0 and vertical_diff <= 120.0 and player.global_position.y > obj.global_position.y:
		var player_dir = sign(player.global_position.x - obj.global_position.x)
		var facing_dir = 1 if not obj.animated_sprite_2d.flip_h else -1

		if player_dir == facing_dir:
			if randf() < 0.75:
				change_state(fsm.states.atk_air)

func _adjust_fall_horizontal_movement() -> void:
	var player = obj.get_player()
	var target_x := obj.global_position.x

	if player:
		if obj.in_phase2 and not obj.jump_markers.is_empty():
			var best_marker = obj.get_best_jump_marker_to_player()
			if best_marker and best_marker.global_position.y > obj.global_position.y:
				target_x = best_marker.global_position.x
			else:
				target_x = player.global_position.x
		else:
			target_x = player.global_position.x

		var lb: Rect2 = obj.level_bounds
		if lb.size.x > 0.0:
			target_x = clamp(target_x, lb.position.x, lb.position.x + lb.size.x)

		var dir_x = sign(target_x - obj.global_position.x)
		obj.velocity.x = dir_x * obj.air_horizontal_speed

func _update_current_jump_marker() -> void:
	var nearest_marker = obj.get_nearest_jump_marker()
	if nearest_marker:
		var distance = obj.global_position.distance_to(nearest_marker.global_position)
		if distance < 50.0:  
			obj.current_jump_marker = nearest_marker
		else:
			obj.current_jump_marker = null
