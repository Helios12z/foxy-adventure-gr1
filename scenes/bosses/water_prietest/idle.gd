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

	if obj.in_phase2:
		change_state(fsm.states.surf)
	else:
		change_state(fsm.states.walk)
