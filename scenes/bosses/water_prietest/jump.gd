extends WaterPrietestState

const EXTRA_JUMP_HEIGHT := 24.0

func _enter() -> void:
	obj.change_animation("jump")
	if obj.jump_sound:
		obj.jump_sound.play()

	control_jump_enter(EXTRA_JUMP_HEIGHT)

func _update(delta: float) -> void:
	control_jump_update(delta, fsm.states.surf, fsm.states.idle)
