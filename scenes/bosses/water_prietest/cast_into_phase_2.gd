extends WaterPrietestState

var _transition_timer: float = 0.0
var _flash_duration: float = 0.4
var _total_duration: float = 1.2  

func _enter() -> void:
	obj.change_animation("hurt")
	_transition_timer = 0.0

	obj.velocity = Vector2.ZERO

func _update(delta: float) -> void:
	_transition_timer += delta

	if _transition_timer < _flash_duration:
		if fmod(_transition_timer, 0.1) < 0.05:
			obj.flash_hurt(0.05, 1, Color.WHITE)

	if _transition_timer >= _total_duration:
		obj._finish_phase2_transition()
		change_state(fsm.states.surf)

func _exit() -> void:
	pass
