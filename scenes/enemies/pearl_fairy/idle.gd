extends EnemyState

@export var idle_radius: float = 120.0

var _target_pos: Vector2

func _enter() -> void:
	obj.change_animation("idle")
	_target_pos = obj.initial_marker_pos
	if obj.has_node("Direction/MoveMarker2D"):
		var m: Marker2D = obj.get_node("Direction/MoveMarker2D")
		m.global_position = obj.initial_marker_pos
	_pick_new_target()

func _update(delta: float) -> void:
	var to_t := _target_pos - obj.global_position
	var dist := to_t.length()
	if dist <= 6.0:
		_pick_new_target()
	else:
		var dir := to_t.normalized()
		obj.velocity = dir * obj.movement_speed
		if absf(obj.velocity.x) > 0.01:
			obj.change_direction(1 if obj.velocity.x > 0.0 else -1)
	# Tránh vật cản: nếu va chạm tường hoặc có collision thì chọn mục tiêu mới
	if obj.is_on_wall() or obj.get_slide_collision_count() > 0:
		_pick_new_target()

func _pick_new_target() -> void:
	var center := _get_idle_center()
	var angle := randf() * TAU
	var r := idle_radius * sqrt(randf())
	_target_pos = center + Vector2(cos(angle), sin(angle)) * r

func _get_idle_center() -> Vector2:
	return obj.initial_marker_pos
