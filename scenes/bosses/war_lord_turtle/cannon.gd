extends RigidBody2D
class_name WarlordCannon

@export var move_speed: float = 60.0
@export var spike_damage: int = 70
@export var max_travel_distance: float = 1200.0
@export var gravity_scale_override: float = 1.0  

var dir: Vector2 = Vector2.RIGHT

var _origin_x: float
var _exploding := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea2D

func _ready() -> void:
	gravity_scale = gravity_scale_override
	_origin_x = global_position.x

	if hit_area:
		if hit_area.has_signal("body_entered"):
			hit_area.body_entered.connect(_on_hit_body_entered)
		if hit_area.has_signal("area_entered"):
			hit_area.area_entered.connect(_on_hit_area_entered)
		if "damage" in hit_area:
			hit_area.damage = spike_damage

	_set_horizontal_speed()
	_update_sprite_facing()

func _physics_process(_delta: float) -> void:
	_set_horizontal_speed()

	if absf(global_position.x - _origin_x) >= max_travel_distance:
		explode()

func set_direction(face: int) -> void:
	if face == 0:
		face = 1
	dir = Vector2(face, 0.0).normalized()
	_set_horizontal_speed()
	_update_sprite_facing()

func _set_horizontal_speed() -> void:
	var v := linear_velocity
	v.x = dir.normalized().x * move_speed
	linear_velocity = v

func _update_sprite_facing() -> void:
	if sprite:
		sprite.scale.x = -sign(dir.x)

func _on_hit_body_entered(body: Node) -> void:
	if _exploding:
		return
	explode()

func _on_hit_area_entered(area: Area2D) -> void:
	if _exploding:
		return
		
	if area.is_in_group("player_attack"):
		dir.x *= -1.0
		_set_horizontal_speed()
		_update_sprite_facing()

func explode() -> void:
	if _exploding:
		return
	_exploding = true
	queue_free()
