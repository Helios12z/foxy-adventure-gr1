extends EnemyState

func _enter() -> void:
	timer = obj.revive_delay
	obj.change_animation("temporary_dead")
	obj.velocity = Vector2.ZERO
		
func _update( _delta ):
	if update_timer(_delta):
		change_state(fsm.states.resurrect)
