extends EnemyState

func _enter()->void:
	obj.change_animation("hurt")
	timer=0.75
	
func _update(delta: float)->void:
	if obj.health <= 0:
		change_state(fsm.states.dead)
		return

	if update_timer(delta):
		change_state(fsm.states.idle)
