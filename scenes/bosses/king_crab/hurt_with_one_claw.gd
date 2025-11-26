extends KingCrabState

func _enter() -> void:
	obj.change_animation("hurt_with_one_claw")
	move_hit_collision_at_idle_attack()
	timer = 0.5

func _update(d: float) -> void:
	if obj.health <= 0: 
		change_state(fsm.states.dead)
		return
	if update_timer(d):
		reset_hit_collision_position()
		change_state(fsm.previous_state)
