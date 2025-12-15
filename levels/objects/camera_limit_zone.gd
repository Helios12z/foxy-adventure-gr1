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
	# Continuous check - if player is inside, ensure limit is maintained
	if _player_inside and _player_ref != null:
		var camera = _get_camera(_player_ref)
		if camera and camera.has_method("set_soft_bottom_limit"):
			# Only set if it's different (to avoid spam)
			if camera.bottom_limit_y != bottom_limit_y:
				camera.set_soft_bottom_limit(bottom_limit_y)
				print("[CameraLimitZone] Re-applying limit: %f (was %f)" % [bottom_limit_y, camera.bottom_limit_y])

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

func _on_body_entered(body: Node2D) -> void:
	# Kiểm tra nếu là Player
	if body.has_method("can_use_skill") or body.name == "Player":
		_player_inside = true
		_player_ref = body
		
		var camera = _get_camera(body)
		if camera and camera.has_method("set_soft_bottom_limit"):
			camera.set_soft_bottom_limit(bottom_limit_y)
			_current_limit = bottom_limit_y
			print("[CameraLimitZone] Player entered - Camera limit changed to: %f" % bottom_limit_y)

func _on_body_exited(body: Node2D) -> void:
	# Kiểm tra nếu là Player
	if body.has_method("can_use_skill") or body.name == "Player":
		# Double-check player actually left using position check
		await get_tree().create_timer(0.1).timeout  # Small delay to avoid false exits
		
		# Check if player is still overlapping
		var still_inside = false
		for overlap_body in get_overlapping_bodies():
			if overlap_body == body:
				still_inside = true
				break
		
		if still_inside:
			print("[CameraLimitZone] False exit detected - player still inside")
			return
		
		# Player actually left
		_player_inside = false
		_player_ref = null
		
		if not restore_limit_on_exit:
			return
		
		var camera = _get_camera(body)
		if camera and camera.has_method("set_soft_bottom_limit"):
			camera.set_soft_bottom_limit(exit_limit_y)
			_current_limit = exit_limit_y
			print("[CameraLimitZone] Player exited - Camera limit restored to: %f" % exit_limit_y)
