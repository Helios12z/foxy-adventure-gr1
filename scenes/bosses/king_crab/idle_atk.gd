extends KingCrabState

func _enter() -> void:
	obj.change_animation("idle_atk")
	move_hit_collision_at_idle_attack()

func _update(delta: float) -> void:
	if obj.claw_returned:
		reset_hit_collision_position()
		change_state(fsm.states.idle_stun)
		
func _exit()->void:
	reset_hit_collision_position()
