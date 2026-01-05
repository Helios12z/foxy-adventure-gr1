extends EnemyState

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity = Vector2.ZERO
	obj.hit_collision_shape_2d.disabled = true 
	timer = 1.25
	
func _update( _delta ):
	if update_timer(_delta):
		obj.queue_free()
