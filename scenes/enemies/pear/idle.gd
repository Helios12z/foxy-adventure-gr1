extends EnemyState

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity.x = 0
	
func _update(d: float) -> void:
	if obj.can_detect_player(): 
		change_state(fsm.states.detect)
