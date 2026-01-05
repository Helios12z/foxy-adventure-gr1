extends EnemyState

var attack_sound_played := false
var bullet_spawned := false

func _enter() -> void:
	obj.velocity.x = 0
	obj.change_animation("attack")
	obj.attack_collision_shape_2d.disabled = true

	attack_sound_played = false
	bullet_spawned = false

func _update(_delta: float) -> void:
	var current_frame = obj.animated_sprite_2d.frame

	if current_frame >= 6 and current_frame <= 8:
		obj.attack_collision_shape_2d.disabled = false

		if not attack_sound_played:
			obj.attack.play(0.25)
			attack_sound_played = true

		if not bullet_spawned:
			spawn_bullet()
			bullet_spawned = true

	if current_frame >= 9:
		obj.attack_collision_shape_2d.disabled = true
		if attack_sound_played:
			obj.attack.stop()

	if not obj.animated_sprite_2d.is_playing():
		obj.attack_collision_shape_2d.disabled = true
		change_state(fsm.states.idle)

func spawn_bullet() -> void:
	if obj.bullet_scene == null:
		return

	var b = obj.bullet_scene.instantiate()
	if b == null:
		return

	var spawn_pos: Vector2 = obj.shoot_point.global_position
	get_tree().current_scene.add_child(b)
	b.global_position = spawn_pos

	var dir_x: float
	if obj.direction > 0:
		dir_x = 1.0
	else: dir_x = -1.0
	var shoot_dir := Vector2(dir_x, 0)

	b.launch(spawn_pos, shoot_dir)
