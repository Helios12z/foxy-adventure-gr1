extends EnemyState

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity = Vector2.ZERO
	timer = 1.25
	obj.drop_coins()

	# Disable all collision shapes
	obj.set_hurt_collision(false)
	obj.set_hit_collision(false)
	if obj.spear_collision_shape_2d:
		obj.spear_collision_shape_2d.disabled = true

# Ignore all damage when dead
func take_damage(_damage_dir: Vector2, _damage: int) -> void:
	pass

func _update( _delta ):
	if update_timer(_delta):
		obj.queue_free()
