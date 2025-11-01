extends EnemyState

func _enter() -> void:
	obj.change_animation("atk1_fire")
	obj.claw_origin = obj.global_position
	var dir_x = obj.get_facing()
	obj.claw_target = obj.claw_origin + Vector2(dir_x * obj.attack_range, 0.0)

	obj.current_claw = obj.control_spawn_claw(obj.claw_origin) # prefab có HitArea2D
	obj.claw_phase_out = true

	# nếu bullet có hàm launch() → bay thẳng rồi tự quay về
	if obj.current_claw and obj.current_claw.has_method("launch"):
		obj.current_claw.launch(obj, obj.claw_origin, obj.claw_target)

	change_state(fsm.states.idle_atk) # vào trạng thái mất càng (đợi trở về)
