extends EnemyState

@export var chase_speed = 150

func _enter() -> void:
	obj.change_animation("walk")


func _update(delta: float) -> void:
	# Check if health is below 50% and retreat
	if obj.should_retreat():
		change_state(fsm.states.retreat)
		return

	if obj.can_detect_player():
		obj.velocity.x = obj.direction * chase_speed
		if obj.is_in_attack_scope():
			change_state(fsm.states.attack)
	else:
		change_state(fsm.states.walk)
	
