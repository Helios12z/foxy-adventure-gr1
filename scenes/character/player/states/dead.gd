extends PlayerState

func _enter():
	#change animation to dead
	obj.change_animation("dead")
	obj.velocity.x = 0
	timer = 2


func _update(delta: float):
	if update_timer(delta):
		change_state(fsm.states.idle)
		GameManager.respawn_at_checkpoint()
		get_parent().get_parent().get_parent().get_node("Checkpoint").active_animation()

# Ignore take damage
func take_damage(_damage: int = 1) -> void:
	pass
