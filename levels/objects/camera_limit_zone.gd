extends Area2D
class_name CameraLimitZone

## Zone để thay đổi giới hạn camera khi player đi vào
## Đặt vào map và set bottom_limit_y cho từng zone

@export var bottom_limit_y: float = INF
@export var restore_limit_on_exit: bool = true
@export var exit_limit_y: float = 230.0  # Giá trị khi ra khỏi zone

var _current_limit: float = -1.0  # Track current limit to avoid redundant sets
var _player_inside: bool = false  # Track if player is actually inside
var _player_ref: Node2D = null  # Reference to player

func _ready() -> void:
	# Chỉ detect player
	collision_layer = 0
	collision_mask = 2  # Player ở layer 2
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("[CameraLimitZone] Ready at position %v, limit will be: %f" % [global_position, bottom_limit_y])

func _process(_delta: float) -> void:
	# Tìm player nếu chưa có reference (hoặc mất reference do invulnerable)
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
	
	if _player_ref == null:
		return
	
	# Kiểm tra liên tục xem player có trong zone không bằng position check
	# (không phụ thuộc vào collision layer/mask)
	var player_in_zone = _is_point_in_zone(_player_ref.global_position)
	
	# Update state
	if player_in_zone and not _player_inside:
		# Player vừa vào zone
		_on_player_enter(_player_ref)
	elif not player_in_zone and _player_inside:
		# Player vừa ra khỏi zone
		_on_player_exit(_player_ref)
	elif player_in_zone and _player_inside:
		# Player vẫn trong zone - đảm bảo camera limit được maintain
		var camera = _get_camera(_player_ref)
		if camera and camera.has_method("set_soft_bottom_limit"):
			# Only set if it's different (to avoid spam)
			if camera.bottom_limit_y != bottom_limit_y:
				camera.set_soft_bottom_limit(bottom_limit_y)
				print("[CameraLimitZone] Re-applying limit: %f (was %f)" % [bottom_limit_y, camera.bottom_limit_y])

func _find_player() -> Node2D:
	# Tìm player qua group - reliable nhất
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null

func _is_point_in_zone(point: Vector2) -> bool:
	# Kiểm tra xem một point có trong zone không
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is RectangleShape2D:
				var rect_shape = shape as RectangleShape2D
				var local_point = to_local(point)
				var half_size = rect_shape.size / 2.0
				
				# Check if point is inside rectangle
				if abs(local_point.x - child.position.x) <= half_size.x and \
				   abs(local_point.y - child.position.y) <= half_size.y:
					return true
			elif shape is CircleShape2D:
				var circle_shape = shape as CircleShape2D
				var local_point = to_local(point)
				var distance = local_point.distance_to(child.position)
				if distance <= circle_shape.radius:
					return true
	return false

func _get_camera(body: Node2D):
	# Tìm camera - thử nhiều cách
	var camera = body.get_node_or_null("CameraFollow")
	if not camera:
		# Tìm child bất kỳ là Camera2D
		for child in body.get_children():
			if child is Camera2D:
				camera = child
				break
	return camera

func _on_player_enter(body: Node2D) -> void:
	_player_inside = true
	_player_ref = body
	
	var camera = _get_camera(body)
	if camera and camera.has_method("set_soft_bottom_limit"):
		camera.set_soft_bottom_limit(bottom_limit_y)
		_current_limit = bottom_limit_y
		print("[CameraLimitZone] Player entered - Camera limit changed to: %f" % bottom_limit_y)

func _on_player_exit(body: Node2D) -> void:
	_player_inside = false
	
	if not restore_limit_on_exit:
		return
	
	var camera = _get_camera(body)
	if camera and camera.has_method("set_soft_bottom_limit"):
		camera.set_soft_bottom_limit(exit_limit_y)
		_current_limit = exit_limit_y
		print("[CameraLimitZone] Player exited - Camera limit restored to: %f" % exit_limit_y)

# Keep signal handlers for backwards compatibility
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("can_use_skill") or body.name == "Player":
		if _player_ref == null:
			_player_ref = body

func _on_body_exited(body: Node2D) -> void:
	pass  # Position check will handle this
