extends WaterPrietestState

@export var walk_speed: float = 60.0  # tuỳ bạn chỉnh, hoặc dùng obj.movement_speed

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta: float) -> void:
	var player = obj.get_player()
	if player == null:
		change_state(fsm.states.idle)
		return

	var dist_x := get_horizontal_distance_to_player()

	# Nếu đã vào tầm atk1 -> dừng & đánh
	if dist_x <= obj.atk1_range:
		obj.velocity.x = 0.0
		change_state(fsm.states.atk_1)
		return

	# Chưa vào tầm -> tiếp tục đi về phía player
	var dir = sign(player.global_position.x - obj.global_position.x)
	obj.velocity.x = dir * walk_speed
