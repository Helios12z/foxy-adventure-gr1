extends RigidBody2D

@export var damage: int = 10
@export var lifetime: float = 5.0

@onready var hit_area: HitArea2D = $HitArea2D

var _timer: float = 0.0

func _ready() -> void:
	hit_area.damage = damage
	hit_area.hitted.connect(_on_hit)
	# Disable gravity so bullet rolls on ground instead of flying
	gravity_scale = 0.0

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()

func _on_hit(_area: Area2D) -> void:
	queue_free()
