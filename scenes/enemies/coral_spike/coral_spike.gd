extends BaseCharacter

@export var show_interval: float = 6.0
@export var show_hit_delay: float = 0.25
@export var show_duration: float = 2.0

@onready var direction_node: Node2D = $Direction
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var hit_shape: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D

func _ready() -> void:
	set_ignore_gravity(true)
	super._ready()
	_set_hit_enabled(false)
	fsm = FSM.new(self, $States, $States/Idle)
	

func _set_hit_enabled(enabled: bool) -> void:
	if hit_shape:
		hit_shape.disabled = not enabled

func enable_hit_area(on: bool) -> void:
	_set_hit_enabled(on)
