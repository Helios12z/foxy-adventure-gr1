extends EnemyState

func _enter() -> void:
	obj.change_animation("walk")
	obj.walking.play()

func _update( _delta ):
	if obj.can_detect_player():
		obj.velocity.x = obj.boss_speed * obj.direction
	if obj.is_in_attack_scope():
			change_state(fsm.states.attack)
	if _should_turn_around():
		obj.turn_around()
		
func _exit() -> void:
	obj.walking.stop()
