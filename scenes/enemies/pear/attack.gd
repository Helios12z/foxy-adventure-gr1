extends EnemyState

var attack_time: float = 0.45

func _enter() -> void:
	obj.change_animation("attack")
	obj.spear_collision_shape_2d.disabled = true
	timer = attack_time

func _update(delta: float) -> void:
	var current_frame = obj.animated_sprite_2d.frame

	if current_frame == 1:
		obj.spear_collision_shape_2d.disabled = false
	else:
		obj.spear_collision_shape_2d.disabled = true

	if update_timer(delta):
		obj.spear_collision_shape_2d.disabled = true

		if obj.can_detect_player():
			fsm.change_state(fsm.states.idle_atk)
		else:
			fsm.change_state(fsm.states.idle)
