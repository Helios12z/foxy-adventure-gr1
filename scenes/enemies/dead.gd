extends EnemyState


func _enter():
	obj.change_animation("dead")
	timer = 1.0
	obj.velocity.x = 0
	obj.set_hurt_collision(false)


func _update(delta):
	if update_timer(delta):
		obj.queue_free()
