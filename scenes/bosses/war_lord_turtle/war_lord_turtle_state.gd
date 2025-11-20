extends EnemyState
class_name WarlordTurtleState

# -------------- SKILL 1: BOMBS --------------
func _spawn_bomb(from_node: Node2D, dir_vec: Vector2) -> void:
	if from_node == null or obj.bomb_scene == null:
		return

	var b = obj.bomb_scene.instantiate()
	var parent := obj.get_tree().current_scene if obj.get_tree().current_scene != null else obj.get_parent()
	parent.add_child(b)

	if b is Node2D:
		(b as Node2D).global_position = from_node.global_position

	# truyền tham số sang bomb (Cannon)
	if "move_speed" in b:
		b.move_speed = obj.bomb_move_speed
	if "dir" in b:
		b.dir = dir_vec.normalized()
	if "spike_damage" in b:
		b.spike_damage = obj.spike_damage
	if b.has_method("set_direction"):
		b.set_direction(-1 if dir_vec.x < 0.0 else 1)

# -------------- SKILL 2: MISSILES --------------
func spawn_rocket_from_index(rocket_index: int, gun_index: int) -> void:
	if obj.missile_scene == null:
		return
	if obj._missile_targets.is_empty():
		return
	if rocket_index < 0 or rocket_index >= obj._missile_targets.size():
		return

	var guns := [obj.atk_2_shoot_point_1, obj.atk_2_shoot_point_2]
	if gun_index < 0 or gun_index >= guns.size():
		return

	var gun: Node2D = guns[gun_index]
	var target_node: Node2D = obj._missile_targets[rocket_index]
	_fire_missile(gun, target_node.global_position)


func _fire_missile(from_node: Node2D, target_pos: Vector2) -> void:
	if obj.missile_scene == null:
		return

	var m = obj.missile_scene.instantiate()

	if m is Node2D:
		(m as Node2D).global_position = (from_node.global_position if from_node else obj.global_position)

	if m.has_method("init"):
		m.init(target_pos, obj.attack_speed, obj.attack_damage_boss)

	var parent := obj.get_tree().current_scene if obj.get_tree().current_scene != null else obj.get_parent()
	parent.add_child(m)
