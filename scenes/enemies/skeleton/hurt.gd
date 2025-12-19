extends EnemyState

func _enter():
	if fsm.previous_state == fsm.states.resurrect:
		fsm.change_state(fsm.states.idle)
	if fsm.previous_state == fsm.states.temporarydead: 
		fsm.change_state(fsm.states.dead)
	obj.change_animation("hit")
	timer = 0.5

func _update(delta: float):
	if update_timer(delta):
		if obj.health <= 0:
			change_state(fsm.states.temporarydead)
		else:
			change_state(fsm.previous_state)
