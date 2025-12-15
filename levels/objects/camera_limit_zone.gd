extends Area2D
class_name CameraLimitZone

## Zone để thay đổi giới hạn camera khi player đi vào
## Đặt vào map và set bottom_limit_y cho từng zone

@export var bottom_limit_y: float = INF
@export var restore_limit_on_exit: bool = true
@export var exit_limit_y: float = 230.0  # Giá trị khi ra khỏi zone

var _current_limit: float = -1.0  # Track current limit to avoid redundant sets

func _ready() -> void:
	# Chỉ detect player
	collision_layer = 0
	collision_mask = 2  # Player ở layer 2
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("[CameraLimitZone] Ready at position %v, limit will be: %f" % [global_position, bottom_limit_y])

func _on_body_entered(body: Node2D) -> void:
	# Kiểm tra nếu là Player
	if body.has_method("can_use_skill") or body.name == "Player":
		# Tránh set lại nếu đã set rồi
		if _current_limit == bottom_limit_y:
			return
		
		# Tìm camera - thử nhiều cách
		var camera = null
		
		# Cách 1: Tìm theo tên
		camera = body.get_node_or_null("CameraFollow")
		if not camera:
			# Cách 2: Tìm child bất kỳ là Camera2D
			for child in body.get_children():
				if child is Camera2D:
					camera = child
					break
		
		if camera and camera.has_method("set_soft_bottom_limit"):
			camera.set_soft_bottom_limit(bottom_limit_y)
			_current_limit = bottom_limit_y
			print("[CameraLimitZone] Camera limit changed to: %f" % bottom_limit_y)

func _on_body_exited(body: Node2D) -> void:
	if not restore_limit_on_exit:
		return
	
	# Kiểm tra nếu là Player
	if body.has_method("can_use_skill") or body.name == "Player":
		# Tránh set lại nếu đã set rồi
		if _current_limit == exit_limit_y:
			return
		
		# Tìm camera
		var camera = null
		camera = body.get_node_or_null("CameraFollow")
		if not camera:
			for child in body.get_children():
				if child is Camera2D:
					camera = child
					break
		
		if camera and camera.has_method("set_soft_bottom_limit"):
			camera.set_soft_bottom_limit(exit_limit_y)
			_current_limit = exit_limit_y
			print("[CameraLimitZone] Camera limit restored to: %f" % exit_limit_y)
