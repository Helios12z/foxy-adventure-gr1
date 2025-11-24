extends HassasinState

func _enter() -> void:
	obj.change_animation("idle")

func _update(_delta: float) -> void:
	if not obj.seen_player:
		return

	decide_move_mode_towards_player()

	change_state(fsm.states.run)
