extends EnemyState

func _enter():
	obj.change_animation("hit")
	timer = 0.5

func _update( delta: float):
	if update_timer(delta):
		if obj.health <= 0:
			change_state(fsm.states.dead)
		else:
			change_state(fsm.previous_state)
