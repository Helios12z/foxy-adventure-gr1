extends RigidBody2D

@export var move_speed: float = 100.0
@export var spike_damage: int = 70
@export var max_travel_distance: float = 1400.0
@export var gravity_scale_override: float = 1.0  
@export var explosion: PackedScene   

var dir: Vector2 = Vector2.RIGHT
var _origin_x: float
var _exploding := false
var _travel_distance: float = 0.0
var _last_pos: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea2D
@onready var hurt_area_2d: HurtArea2D = $HurtArea2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D 

func _ready() -> void:
	gravity_scale = gravity_scale_override
	_origin_x = global_position.x

	if hit_area:
		hit_area.damage = spike_damage
		if hit_area.has_signal("area_entered"):
			hit_area.area_entered.connect(_on_hit_area_entered)

	if hurt_area_2d:
		if hurt_area_2d.has_signal("hurt"):
			hurt_area_2d.hurt.connect(_on_hurt_area_hurt)

	_set_horizontal_speed()
	_update_sprite_facing()

func _physics_process(_delta: float) -> void:
	if _exploding:
		return
	_set_horizontal_speed()
	_travel_distance += global_position.distance_to(_last_pos)
	_last_pos = global_position
	if _travel_distance >= max_travel_distance:
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

func _on_hit_area_entered(area: Area2D) -> void:
	if _exploding:
		return
	explode()

func _on_hurt_area_hurt(_hit_dir: Vector2, _dmg: float) -> void:
	if _exploding:
		return
	dir.x *= -1.0
	_set_horizontal_speed()
	_update_sprite_facing()

func explode() -> void:
	if _exploding:
		return
	_exploding = true
	_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	if explosion == null:
		return
	var ex = explosion.instantiate()
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(ex)
	ex.global_position = global_position
