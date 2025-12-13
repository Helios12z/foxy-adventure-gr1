extends Marker2D
class_name JumpMarker2D

signal marker_activated
signal marker_deactivated

@export var marker_id: String = ""
@export var is_active: bool = true
@export var platform_size: Vector2 = Vector2(64, 32)
@export var jump_priority: float = 1.0  
@export var is_safe_spot: bool = true  

@export var connected_markers: Array[JumpMarker2D] = []

@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area: Area2D = $Area2D

func _ready() -> void:
	add_to_group("jump_markers")

	if area:
		area.body_entered.connect(_on_body_entered)

	if connected_markers.is_empty():
		_find_connected_markers()

func _find_connected_markers() -> void:
	var jump_markers = get_tree().get_nodes_in_group("jump_markers")
	for marker in jump_markers:
		if marker != self and _can_reach_marker(marker):
			connected_markers.append(marker)

func _can_reach_marker(target: JumpMarker2D) -> bool:
	if not target or not target.is_active:
		return false

	var h_dist = abs(global_position.x - target.global_position.x)
	var v_dist = abs(global_position.y - target.global_position.y)

	var max_horizontal = 180.0
	var max_vertical_upward = 100.0  
	var max_vertical_downward = 150.0  

	return h_dist <= max_horizontal and \
		   ((v_dist <= max_vertical_upward) if target.global_position.y < global_position.y else (v_dist <= max_vertical_downward))

func set_active(active: bool) -> void:
	is_active = active

	if active:
		marker_activated.emit()
	else:
		marker_deactivated.emit()

func get_best_jump_to_target(target_pos: Vector2) -> JumpMarker2D:
	if not is_active:
		return null

	var best_marker = null
	var best_score = INF

	var markers_to_check = [self] + connected_markers

	for marker in markers_to_check:
		if not marker or not marker.is_active:
			continue

		var distance = marker.global_position.distance_to(target_pos)
		var score = distance - (marker.jump_priority * 20.0)
		if not marker.is_safe_spot:
			score += 50.0  

		if score < best_score:
			best_score = score
			best_marker = marker

	return best_marker

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("destructible_platform"):
		set_active(false)

func get_jump_path_to_target(target: JumpMarker2D) -> Array[JumpMarker2D]:
	if not target or not target.is_active:
		return []

	if target in connected_markers:
		return [target]

	for intermediate in connected_markers:
		if not intermediate or not intermediate.is_active:
			continue
		if target in intermediate.connected_markers:
			return [intermediate, target]

	return []  
