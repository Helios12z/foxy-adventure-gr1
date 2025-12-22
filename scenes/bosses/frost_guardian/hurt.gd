extends EnemyState

func _enter() -> void:
	obj.change_animation("hit")
	timer = 1.4
	
func _update( _delta ):
	if update_timer(_delta):
		change_state(fsm.states.attack)
