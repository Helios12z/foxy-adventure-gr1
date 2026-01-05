extends EnemyState

@onready var mushroom_zombie_scene = preload("res://scenes/enemies/mushroom_zoombie/mushroom_zombie.tscn")

func _enter():
	# Only spawn mini mushrooms if this is NOT a mini version
	if not obj.is_mini:
		_spawn_mini_mushrooms()

	# Parent death behavior
	obj.change_animation("dead")
	obj.gravity = 700
	timer = 1.0
	obj.velocity.x = 0
	obj.set_hurt_collision(false)
	obj.set_hit_collision(false)
	obj.disable_check_player_in_sight()
	obj.drop_coins()

func _spawn_mini_mushrooms():
	var parent = obj.get_parent()
	if parent == null:
		return

	# Get current stats
	var current_health = obj.max_health / 2
	var current_scale = obj.scale / 2

	# Get HitArea2D to extract damage
	var hit_area = obj.get_node_or_null("Direction/HitArea2D")
	var current_damage = 15  # Default fallback
	if hit_area and hit_area.has_method("get"):
		current_damage = hit_area.damage / 2

	# Spawn 2 mini mushrooms
	for i in range(2):
		var mini = mushroom_zombie_scene.instantiate()
		mini.is_mini = true
		mini.max_health = current_health
		mini.health = current_health
		mini.scale = current_scale

		# Set damage on the HitArea2D
		var mini_hit_area = mini.get_node_or_null("Direction/HitArea2D")
		if mini_hit_area:
			mini_hit_area.damage = current_damage

		# Position slightly apart
		var offset = -40 if i == 0 else 40
		mini.global_position = obj.global_position + Vector2(offset, 0)

		parent.add_child(mini)

func _update(delta):
	if update_timer(delta):
		obj.queue_free()
