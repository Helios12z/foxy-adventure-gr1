extends AnimatableBody2D

@export var move_speed: float = 200.0      # tốc độ tối đa
@export var move_distance: float = 200.0   # khoảng cách di chuyển
@export var acceleration: float = 600.0    # gia tốc (càng lớn thì đổi hướng càng nhanh)

var start_position: Vector2

# Direction of movement # 1: Up # -1: Down
var direction: int = 1
var velocity: float = 0.0

func _ready():
	start_position = global_position

func _physics_process(delta):
	var target_y = start_position.y + (move_distance * direction)

	# Khi gần tới biên thì đổi hướng
	if global_position.y >= start_position.y + move_distance:
		direction = -1
	elif global_position.y <= start_position.y - move_distance:
		direction = 1

	# Dùng linear interpolation cho velocity để mượt
	var target_velocity = move_speed * direction
	velocity = move_toward(velocity, target_velocity, acceleration * delta)

	# Cập nhật vị trí
	global_position.y += velocity * delta
