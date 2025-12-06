# States/Surf.gd
extends WaterPrietestState

@export var surf_speed: float = 120.0  # nhanh hơn walk cho phase 2

func _enter() -> void:
	obj.change_animation("surf")

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

	# Chưa vào tầm -> trượt về phía player
	var dir = sign(player.global_position.x - obj.global_position.x)
	obj.velocity.x = dir * surf_speed
