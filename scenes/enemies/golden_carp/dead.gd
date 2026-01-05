extends EnemyState

var weapon_scene = preload("res://scenes/enemies/golden_carp/dropped_weapon.tscn")

func _enter():
	obj.change_animation("dead")
	obj.gravity = 700
	timer = 1.0
	obj.velocity.x = 0
	obj.set_hurt_collision(false)
	obj.set_hit_collision(false)
	obj.disable_check_player_in_sight()
	obj.drop_coins()
	
	_spawn_weapons()

func _update(delta):
	if update_timer(delta):
		obj.queue_free()

func _spawn_weapons():
	# Spawn 2 weapons throwing in opposite directions but closer to the center
	# First one slightly to the left
	_spawn_single_weapon(-60.0, -20.0)
	# Second one slightly to the right
	_spawn_single_weapon(20.0, 60.0)

func _spawn_single_weapon(min_x: float, max_x: float):
	if weapon_scene:
		var weapon = weapon_scene.instantiate()
		# Add to the current scene so it persists after enemy death
		var scene_root = obj.get_tree().current_scene
		if scene_root:
			scene_root.add_child(weapon)
			weapon.global_position = obj.global_position + Vector2(0, -30) # Spawn slightly above
			
			# Throw it upwards and in the specified X range
			var random_x = randf_range(min_x, max_x)
			var random_y = randf_range(-350.0, -200.0) # Varies throw height a bit
			weapon.velocity = Vector2(random_x, random_y)
