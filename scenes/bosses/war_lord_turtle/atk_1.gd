extends EnemyState

func _enter()->void:
	obj.change_animation("atk_1")
	
func _update(delta: float)->void:
	await obj.do_skill1()
	change_state(fsm.states.idle)
