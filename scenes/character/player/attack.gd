extends PlayerState

func _enter():
	var anim_name = "attack" if obj.is_on_floor() else "jump_attack"
	obj.change_animation(anim_name)
	obj.velocity.x = 0
	obj.set_hit_collision(true)

	timer = 0.5

func _update(delta: float):
	if update_timer(delta):
		change_state(fsm.previous_state)

func _exit():
	obj.set_hit_collision(false)
