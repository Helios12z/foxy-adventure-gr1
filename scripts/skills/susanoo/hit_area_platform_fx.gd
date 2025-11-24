extends Area2D

# Damage applied to HurtArea2D
@export var damage: int = 1

# Scene spawn cho fire hole
@export var firehole_scene: PackedScene = preload("res://scenes/skills/susanoo/fire_hole.tscn")

# Marker2D để chỉ định điểm spawn hole (đặt trong scene và gán NodePath)
@export var hole_marker_path: NodePath
var _hole_marker: Node2D = null

# Nhấc sprite lên nhẹ để tránh lún nền
@export var spawn_offset: Vector2 = Vector2(0, -2)

# Tắt/bật tạo fire hole khi va chạm thân (platform/body). Mặc định: tắt
@export var spawn_firehole_on_body_enter: bool = false

# Signal when something was hit
signal hitted(area)

func _init() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _ready() -> void:
	# Resolve marker theo exported path; nếu trống, thử child "HoleMarker2D" rồi đến parent
	if hole_marker_path != NodePath(""):
		_hole_marker = get_node_or_null(hole_marker_path) as Node2D
	if _hole_marker == null:
		_hole_marker = get_node_or_null("HoleMarker2D") as Node2D
	if _hole_marker == null:
		var p := get_parent()
		if p:
			_hole_marker = p.get_node_or_null("HoleMarker2D") as Node2D

# Apply damage to HurtArea2D
func hit(hurt_area: Area2D) -> void:
	if hurt_area.has_method("take_damage"):
		var hit_dir: Vector2 = hurt_area.global_position - global_position
		hurt_area.take_damage(hit_dir.normalized(), damage)

# Spawn fire hole tại vị trí Marker2D
func _spawn_firehole_at_marker() -> void:
	if firehole_scene == null:
		return
	var marker := _hole_marker
	if marker == null and hole_marker_path != NodePath(""):
		marker = get_node_or_null(hole_marker_path) as Node2D
	if marker == null:
		return
	var hole := firehole_scene.instantiate()
	get_tree().current_scene.add_child(hole)
	hole.global_position = marker.global_position + spawn_offset

# When hitting an Area2D (enemy hurt area), apply damage and emit signal
func _on_area_entered(area: Area2D) -> void:
	hit(area)
	hitted.emit(area)

# When overlapping a physics body (environment/platform), spawn fire hole below
func _on_body_entered(_body: Node) -> void:
	if not spawn_firehole_on_body_enter:
		return
	_spawn_firehole_at_marker()
