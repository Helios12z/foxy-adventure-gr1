extends EnemyState

@export var chase_speed = 150

func _enter() -> void:
	obj.change_animation("walk")

func _update(delta: float) -> void:
	if obj.can_detect_player():
		obj.velocity.x = obj.direction * chase_speed
		if obj.is_in_attack_scope():
			change_state(fsm.states.attack)
	else:
		change_state(fsm.states.walk)
