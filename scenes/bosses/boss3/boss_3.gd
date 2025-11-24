extends BaseCharacter

@export var player_path: NodePath
@onready var player: Node2D = get_node_or_null(player_path)
@onready var sprite = $Direction/AnimatedSprite2D

func _ready() -> void:
	gravity = 0
	super._ready()
	# Nếu chưa gán trong inspector thì tự tìm Player theo group
	if not player:
		player = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if player:
		var dx := player.global_position.x - global_position.x
		if abs(dx) > 1.0:
			# Giả sử sprite mặc định quay sang phải
			sprite.flip_h = dx < 0
