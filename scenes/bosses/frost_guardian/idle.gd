extends EnemyState

func _enter() -> void:
	obj.change_animation("idle")
	obj.collision_shape_2d.disabled = false
	obj.hurt_collision_shape_2d.disabled = false
	obj.hit_collision_shape_2d.disabled = false
	obj.attack_collision_shape_2d.disabled = true
	if not obj.boss_music.is_playing(): 
		obj.boss_music.play()
	obj.gravity = 700.0 
	timer = obj.attack_windup_time
	
func _update( _delta ):
	if obj.is_in_attack_scope():
		change_state(fsm.states.attack)
	if update_timer(_delta):
		change_state(fsm.states.walk)
