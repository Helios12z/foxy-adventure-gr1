extends EnemyState

func _enter():
	obj.change_animation("hit")
	timer = 0.5

func _update( delta: float):
	if update_timer(delta):
		if obj.health <= 0:
			change_state(fsm.states.dead)
		else:
			obj.velocity.y = -100
			if obj.has_meta("force_hurt_return_state"):
				var target := str(obj.get_meta("force_hurt_return_state"))
				obj.remove_meta("force_hurt_return_state")
				if target == "walk":
					change_state(fsm.states.walk)
					return
				if target == "idle":
					change_state(fsm.states.idle)
					return
			change_state(fsm.previous_state)
