extends EnemyState

func _enter() -> void:
	obj.change_animation("idle")
	obj.collision_shape_2d.disabled = false
	obj.hurt_collision_shape_2d.disabled = false
	obj.hit_collision_shape_2d.disabled = false
	obj.attack_collision_shape_2d.disabled = true
	obj.gravity = 700.0 
	obj.velocity.x = 0
	timer = obj.range_attack_windup_time
	
func _update( _delta ):
	if obj.is_in_attack_scope():
		change_state(fsm.states.attack)
	else:
		if update_timer(_delta):
			change_state(fsm.states.rangeattack)
	if obj.can_detect_player(): 
		change_state(fsm.states.walk)
