extends EnemyState

var weapon_scene = preload("res://scenes/enemies/serpent_eel/dropped_weapon.tscn")

func _enter():
	obj.change_animation("dead")
	obj.gravity = 700
	timer = 1.0
	obj.velocity.x = 0
	obj.set_hurt_collision(false)
	obj.disable_check_player_in_sight()
	obj.drop_coins()
	
	_spawn_weapons()

func _update(delta):
	if update_timer(delta):
		obj.queue_free()

func _spawn_weapons():
	# Spawn 9 weapons as requested
	for i in range(9):
		_spawn_single_weapon()

func _spawn_single_weapon():
	if weapon_scene:
		var weapon = weapon_scene.instantiate()
		# Add to the current scene so it persists after enemy death
		var scene_root = obj.get_tree().current_scene
		if scene_root:
			scene_root.add_child(weapon)
			weapon.global_position = obj.global_position + Vector2(0, -30) # Spawn slightly above
			
			# Random chaotic throw
			var random_x = randf_range(-150.0, 150.0) 
			var random_y = randf_range(-350.0, -150.0)
			weapon.velocity = Vector2(random_x, random_y)
