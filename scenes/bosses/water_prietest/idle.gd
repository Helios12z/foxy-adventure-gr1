extends WaterPrietestState

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity.x = 0.0

func _update(_delta: float) -> void:
	if not obj.seen_player:
		return

	var player = obj.get_player()
	if player == null:
		return

	var dist_x = get_horizontal_distance_to_player()
	var dy := get_vertical_diff_to_player(player)
	var abs_dy = abs(dy)

	# Chỉ tấn công nếu player gần cùng cao độ
	if abs_dy <= SAME_LEVEL_THRESHOLD and dist_x <= obj.atk1_range:
		change_state(fsm.states.atk_1)
		return

	# Nếu chênh cao → chọn mode di chuyển phù hợp (chase hoặc đi về mép để jump/fall)
	decide_move_mode_towards_player()

	# Phase 1: đi bộ, Phase 2: surf
	if obj.in_phase2:
		change_state(fsm.states.surf)
	else:
		change_state(fsm.states.walk)
