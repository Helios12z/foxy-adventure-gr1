extends EnemyState

func _enter() -> void:
	obj.change_animation("walk")
	obj.walking.play()
	timer = obj.range_attack_windup_time

func _update( _delta ):
	if obj.can_detect_player():
		obj.velocity.x = obj.boss_speed * obj.direction
	else:
		change_state(fsm.states.idle)
	if obj.is_in_attack_scope():
		change_state(fsm.states.attack)
	else:
		if update_timer(_delta):
			change_state(fsm.states.rangeattack)
	if _should_turn_around():
		obj.turn_around()

func _exit() -> void:
	obj.walking.stop()
