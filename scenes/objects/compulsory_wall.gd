@tool
extends Node2D

class_name CompulsoryWall

## Wall that only opens when all assigned monsters are killed
## Forces player to fight enemies before proceeding
##
## To create walls of different sizes, create a new inherited scene:
## 1. Right-click CompulsoryWall.tscn in FileSystem
## 2. Choose "New Inherited Scene"
## 3. Edit the TileMapLayer to your desired size
## 4. Save with a descriptive name (e.g., CompulsoryWall_Tall.tscn)

@export_group("Rotation Configuration")
@export_enum("Portrait:0", "Landscape:1") var rotation_mode: int = 0:
	set(value):
		if rotation_mode != value:
			rotation_mode = value
			_update_rotation()

@export_group("Slide Configuration")
@export_enum("Up:0", "Down:1", "Left:2", "Right:3") var slide_direction: int = 0
@export var slide_distance: float = 200.0
@export var slide_duration: float = 0.5

@export_group("Enemy Configuration")
## Assign the enemies that must be killed to open this wall
@export var required_enemies: Array[NodePath] = []

var _tracked_enemies: Array[Node] = []
var _is_opening: bool = false

signal wall_opened


func _ready() -> void:
	_update_rotation()

	if not Engine.is_editor_hint():
		_connect_to_enemies()


func _update_rotation() -> void:
	if not Engine.is_editor_hint():
		match rotation_mode:
			0:
				rotation_degrees = 0
			1:
				rotation_degrees = 90


func _connect_to_enemies() -> void:
	for enemy_path in required_enemies:
		if has_node(enemy_path):
			var enemy = get_node(enemy_path)
			if enemy is EnemyCharacter:
				_tracked_enemies.append(enemy)
				enemy.tree_exiting.connect(_on_enemy_killed.bind(enemy))


func _on_enemy_killed(enemy: Node) -> void:
	if _is_opening:
		return

	_tracked_enemies.erase(enemy)
	print("[CompulsoryWall] Enemy killed: %s. Remaining: %d" % [enemy.name, _tracked_enemies.size()])

	if _tracked_enemies.is_empty():
		_start_opening_sequence()


func _start_opening_sequence() -> void:
	if _is_opening:
		return

	_is_opening = true
	print("[CompulsoryWall] All enemies defeated! Starting opening sequence...")

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(_slide_away)


func _slide_away() -> void:
	var slide_tween = create_tween()
	slide_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

	var target_pos := position
	match slide_direction:
		0:
			target_pos += Vector2(0, -slide_distance)
		1:
			target_pos += Vector2(0, slide_distance)
		2:
			target_pos += Vector2(-slide_distance, 0)
		3:
			target_pos += Vector2(slide_distance, 0)

	slide_tween.tween_property(self, "position", target_pos, slide_duration)
	slide_tween.finished.connect(func():
		wall_opened.emit()
		queue_free()
	)
