extends EnemyState

func _enter() -> void:
	timer = obj.revive_delay
	obj.change_animation("temporary_dead")
	obj.set_healthbar_temporary_dead_visual()
	obj.velocity = Vector2.ZERO

func _exit() -> void:
	obj.reset_healthbar_visual()
		
func _update( _delta ):
	if update_timer(_delta):
		obj.is_in_temporary_dead = false
		change_state(fsm.states.resurrect)
