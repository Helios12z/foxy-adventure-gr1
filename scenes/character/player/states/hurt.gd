extends PlayerState
func _enter():
	obj.change_animation("hurt")
	obj.velocity.y = -250
	obj.velocity.x = -50 * sign(obj.velocity.x)
	timer = 0.8


func _update( delta: float):
	if update_timer(delta):
		change_state(fsm.states.idle)
