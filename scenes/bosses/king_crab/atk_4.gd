extends KingCrabState

var first_claw_shot := false
var second_claw_shot := false
var first_claw_node: Node = null
var second_claw_node: Node = null
var atk4_animation_started := false
var animation_finished := false

func _enter() -> void:
	obj.change_animation("atk1_fire")
	timer = 0.25
	first_claw_shot = false
	second_claw_shot = false
	first_claw_node = null
	second_claw_node = null
	atk4_animation_started = false
	animation_finished = false

	if not obj.animated_sprite_2d.animation_finished.is_connected(_on_atk4_animation_finished):
		obj.animated_sprite_2d.animation_finished.connect(_on_atk4_animation_finished)

func _update(d: float) -> void:
	if update_timer(d):
		if not first_claw_shot:
			obj.shoot.play()
			obj.camera.camera_shake()
			first_claw_node = spawn_first_claw_with_dir(obj.queued_bullet_dir_x)
			first_claw_shot = true
			obj.change_animation("atk_idle")
			timer = 0.75
		elif not atk4_animation_started:
			obj.change_animation("atk4")
			atk4_animation_started = true
		elif second_claw_shot:
			change_state(fsm.states.atk4_idle)

	if atk4_animation_started and animation_finished and not second_claw_shot:
		obj.shoot.play()
		obj.camera.camera_shake()
		second_claw_node = spawn_second_claw_with_dir(obj.queued_bullet_dir_x)
		second_claw_shot = true
		timer = 0.3

func _on_atk4_animation_finished() -> void:
	if obj.animated_sprite_2d.animation == "atk4":
		animation_finished = true

func spawn_first_claw_with_dir(dir_x: float) -> Node:
	if obj.bullet_scene == null or obj.claw_busy: return null

	var was_busy = obj.claw_busy
	obj.claw_busy = false

	var bullet = obj.bullet_scene.instantiate()
	if not (bullet and bullet.has_method("launch")):
		obj.claw_busy = was_busy
		return null

	get_tree().current_scene.add_child(bullet)

	var origin: Vector2 = obj.shoot_point.global_position
	var face: float
	if dir_x != 0.0: face = sign(dir_x)
	else: face = sign(obj.boss_direction.scale.x)
	if face == 0: face = 1
	var atk4_range = obj.attack1_range * 2  
	var target := origin + Vector2(face * atk4_range, 0.0)
	bullet.max_range = atk4_range

	bullet.connect("returned", Callable(self, "on_first_claw_returned"))
	bullet.add_to_group("atk4_first_claw")
	bullet.launch(self, origin, target)

	obj.claw_busy = was_busy

	return bullet

func spawn_second_claw_with_dir(dir_x: float) -> Node:
	if obj.bullet_scene == null: return null

	var bullet = obj.bullet_scene.instantiate()
	if not (bullet and bullet.has_method("launch")): return null

	get_tree().current_scene.add_child(bullet)

	var origin: Vector2 = obj.second_claw_shoot_point.global_position
	var face: float
	if dir_x != 0.0: face = sign(dir_x)
	else: face = sign(obj.boss_direction.scale.x)
	if face == 0: face = 1
	var atk4_range = obj.attack1_range * 2  
	var target := origin + Vector2(face * atk4_range, 0.0)
	bullet.max_range = atk4_range

	bullet.connect("returned", Callable(self, "on_second_claw_returned"))
	bullet.add_to_group("atk4_second_claw")
	bullet.launch(self, origin, target)

	return bullet

func on_first_claw_returned() -> void:
	if first_claw_node:
		first_claw_node.remove_from_group("atk4_first_claw")
		first_claw_node = null

func on_second_claw_returned() -> void:
	if second_claw_node:
		second_claw_node.remove_from_group("atk4_second_claw")
		second_claw_node = null

func _on_claws_collided(claw1: Node, claw2: Node) -> void:
	if fsm and fsm.current_state == fsm.states.atk4_idle:
		spawn_boomerang(claw1, claw2)

func _exit() -> void:
	if obj.animated_sprite_2d.animation_finished.is_connected(_on_atk4_animation_finished):
		obj.animated_sprite_2d.animation_finished.disconnect(_on_atk4_animation_finished)
