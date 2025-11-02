extends EnemyState

func _enter() -> void:
	print("enter atk1 windup")
	obj.change_animation("atk1_windup")
	var dir_x := 1.0
	if obj.found_player:
		dir_x = sign(obj.found_player.global_position.x - obj.global_position.x)
	elif obj.has_last_seen:
		dir_x = sign(obj.last_seen_player_x - obj.global_position.x)
	else:
		dir_x = -obj.direction

	if dir_x == 0.0: dir_x = -obj.direction
	obj.queued_bullet_dir_x = dir_x

	timer = 0.2

func _update(d: float) -> void:
	if update_timer(d):
		change_state(fsm.states.atk1_fire)
