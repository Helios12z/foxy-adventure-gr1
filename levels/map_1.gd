extends Node


@export var camera_bottom_limit_y: float = INF

@onready var heartsContainer = $CanvasLayer/HeartsContainer
@onready var player = $Player

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

func _ready() -> void:
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
	heartsContainer.setMaxHearts(player.max_health)

func _process(delta: float) -> void:
	heartsContainer.updateHearts(player.health)
