extends EnemyState

func _enter() -> void:
	obj.change_animation("hurt")
	print("king crab health: ",obj.health)
	timer = 0.5

func _update(d: float) -> void:
	if obj.health <= 0: 
		change_state(fsm.states.dead)
		return
	if update_timer(d):
		change_state(fsm.states.walk)
