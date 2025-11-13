extends Node2D
class_name EnemySpawner

@export var exit_point_path: NodePath
@export var scripted_run_speed: float = 320.0
@export var spawn_interval: float = 0.35

var exit_point: Node2D

const CRAB_SCENE: PackedScene = preload("res://scenes/enemies/crab/crab.tscn")
const MUSHROOM_SCENE: PackedScene = preload("res://scenes/enemies/mushroom/mushroom.tscn")

func _ready() -> void:
	exit_point = get_node_or_null(exit_point_path)
	if exit_point == null:
		exit_point = get_tree().current_scene.get_node_or_null("EnemyExitPoint")

func spawn_crab_at(pos: Vector2) -> EnemyCharacter:
	var e := CRAB_SCENE.instantiate() as EnemyCharacter
	e.global_position = pos
	get_tree().current_scene.add_child(e)
	if exit_point:
		# Tăng tốc chạy theo kịch bản để lao nhanh về marker
		if "run_speed" in e:
			e.run_speed = scripted_run_speed
		e.run_to(exit_point.global_position)
	return e

func spawn_mushroom_at(pos: Vector2) -> EnemyCharacter:
	var e := MUSHROOM_SCENE.instantiate() as EnemyCharacter
	e.global_position = pos
	get_tree().current_scene.add_child(e)
	if exit_point:
		# Tăng tốc chạy theo kịch bản để lao nhanh về marker
		if "run_speed" in e:
			e.run_speed = scripted_run_speed
		e.run_to(exit_point.global_position)
	return e

func spawn_wave_from_house(house: Node, count: int = 3) -> void:
	if house == null:
		return
	# Spawn gần mặt đất hơn: dùng vị trí nhà và nhích xuống nhẹ
	var base := (house as Node2D).global_position + Vector2(0, 8)
	for i in range(count):
		if i % 2 == 0:
			spawn_crab_at(base + Vector2(i * 8, 0))
		else:
			spawn_mushroom_at(base + Vector2(i * 8, 0))

# Spawn tuần tự: 5 crab + 5 mushroom theo thứ tự, mỗi enemy đi ngay
func spawn_sequence_from_house(house: Node, crab_count: int = 5, mushroom_count: int = 5) -> void:
	if house == null:
		return
	var base := (house as Node2D).global_position + Vector2(0, 8)
	var queue: Array[String] = []
	var max_count: int = max(crab_count, mushroom_count)
	for i in range(max_count):
		if i < crab_count:
			queue.append("crab")
		if i < mushroom_count:
			queue.append("mushroom")
	var x_offset := 0
	for kind in queue:
		var pos := base + Vector2(x_offset, 0)
		if kind == "crab":
			spawn_crab_at(pos)
		else:
			spawn_mushroom_at(pos)
		x_offset += 8
		await get_tree().create_timer(spawn_interval).timeout
