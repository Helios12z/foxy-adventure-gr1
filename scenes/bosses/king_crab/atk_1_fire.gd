extends KingCrabState

func _enter() -> void:
	obj.change_animation("atk1_fire")
	timer=0.25

func _update(d: float)->void:
	if update_timer(d):
		obj.camera.camera_shake()
		spawn_bullet_with_dir(obj.queued_bullet_dir_x)
		change_state(fsm.states.idle_atk)
