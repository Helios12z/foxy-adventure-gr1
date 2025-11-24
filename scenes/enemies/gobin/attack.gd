extends EnemyState


func _enter() -> void:
	obj.change_animation("attack")
	obj.set_hit_collision(true)
	obj.velocity.x = 0
	timer = 1


func _exit() -> void:
	obj.set_hit_collision(false)

func _update(delta: float) -> void:
	if update_timer(delta):
		if obj.can_detect_player():
			if not obj.is_in_attack_scope():
				change_state(fsm.states.chase)
		else:
			change_state(fsm.states.idle)
		
