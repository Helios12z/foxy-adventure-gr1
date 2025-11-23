extends WarlordTurtleState

var cast_time: float = 2.0 

func _enter() -> void:
	obj.change_animation("cast")
	timer = cast_time

func _update(d: float) -> void:
	if update_timer(d):
		_spawn_atomic_bomb()
		change_state(fsm.states.stun)
