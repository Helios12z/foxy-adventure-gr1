extends EnemyState
class_name WarlordTurtleState

var _locked_rocket_center: Vector2 = Vector2.ZERO
var _has_locked_center: bool = false

func _spawn_bomb(from_node: Node2D, dir_vec: Vector2) -> void:
	if from_node == null or obj.bomb_scene == null:
		return

	var b = obj.bomb_scene.instantiate()
	var parent := obj.get_tree().current_scene if obj.get_tree().current_scene != null else obj.get_parent()
	parent.add_child(b)

	if b is Node2D:
		(b as Node2D).global_position = from_node.global_position

	if "move_speed" in b:
		b.move_speed = obj.bomb_move_speed
	if "dir" in b:
		b.dir = dir_vec.normalized()
	if "spike_damage" in b:
		b.spike_damage = obj.spike_damage
	if b.has_method("set_direction"):
		b.set_direction(-1 if dir_vec.x < 0.0 else 1)

#I dont think route the rockets to specified points is a good idea so I change it to player lock instead :))
func spawn_rocket_from_index(rocket_index: int, gun_index: int) -> void:
	if obj.missile_scene == null:
		return

	var guns := [obj.atk_2_shoot_point_1, obj.atk_2_shoot_point_2]
	if gun_index < 0 or gun_index >= guns.size():
		return

	var gun: Node2D = guns[gun_index]

	if not _has_locked_center:
		var p = obj._get_player()
		if p != null:
			_locked_rocket_center = p.global_position
		else:
			_locked_rocket_center = obj.global_position
		_has_locked_center = true

	var rocket_count = 4
	var center_index = (rocket_count - 1) / 2.0
	var offset_index = float(rocket_index) - center_index

	var target_x = _locked_rocket_center.x + offset_index * 120 #obj.missile_spread
	var target_y = _locked_rocket_center.y

	if obj.level_bounds.size != Vector2.ZERO:
		var min_x = obj.level_bounds.position.x
		var max_x = obj.level_bounds.position.x + obj.level_bounds.size.x
		target_x = clampf(target_x, min_x, max_x)

	_fire_missile(gun, Vector2(target_x, target_y))


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
