# res://scenes/bosses/king_crab/states/walk.gd
extends EnemyState

func _enter() -> void:
	print("enter walk state")
	obj.change_animation("walk")

func _update(_delta: float) -> void:
	# Quay đầu nếu gặp tường/hố (đã có sẵn trong EnemyState)
	control_walk()

	# Bám theo player nếu có
	if obj.found_player:
		var px = obj.found_player.global_position.x
		if px < obj.global_position.x:
			obj.change_direction(-1)
		else:
			obj.change_direction(1)
		# tiến gần player một nhịp (vẫn move_and_slide ở control_walk)
		obj.velocity.x = obj.direction * obj.movement_speed

		# Quyết định tấn công
		if obj.can_attack1() and obj.next_attack_is_claw:
			change_state(fsm.states.atk1_windup)
		elif obj.can_attack2() and not obj.next_attack_is_claw:
			change_state(fsm.states.atk2_roll)
