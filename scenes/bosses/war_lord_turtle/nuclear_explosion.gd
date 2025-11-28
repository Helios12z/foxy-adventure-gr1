extends Node2D

@export var max_radius: float = 100.0
@export var expand_speed: float = 600.0      
@export var damage: int = 100
@export var lifetime: float = 1.2           
@export var initial_radius: float = 20.0 
@export var fallback_base_radius: float = 0.0

var _current_radius: float = 0.0
var _alive_time: float = 0.0                 

var _base_anim_scale: Vector2             
var _sprite_radius: float = 1.0            

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area: Area2D = $HitArea2D
@onready var shape: CircleShape2D = $HitArea2D/CollisionShape2D.shape as CircleShape2D
@onready var explosion: AudioStreamPlayer2D = $Explosion

func _ready() -> void:
	_base_anim_scale = anim.scale
	explosion.play(0.3)

	var tex: Texture2D = null
	if anim.sprite_frames != null:
		var anim_name := anim.animation
		if anim_name == "":
			var names := anim.sprite_frames.get_animation_names()
			if names.size() > 0:
				anim_name = names[0]
		if anim_name != "":
			tex = anim.sprite_frames.get_frame_texture(anim_name, 0)

	if tex != null:
		var w := tex.get_width() * _base_anim_scale.x
		var h := tex.get_height() * _base_anim_scale.y
		_sprite_radius = min(w, h) * 0.5
	elif fallback_base_radius > 0.0:
		_sprite_radius = fallback_base_radius
	else:
		_sprite_radius = 64.0  

	_current_radius = initial_radius
	shape.radius = _current_radius
	_update_visual_scale()

	hit_area.damage = damage

	anim.frame=0
	anim.play("default")

	anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	_alive_time += delta                         

	_current_radius = min(_current_radius + expand_speed * delta, max_radius)
	shape.radius = _current_radius
	_update_visual_scale()

	if _alive_time >= lifetime and not is_queued_for_deletion():
		explosion.stop()
		queue_free()
	
func _update_visual_scale() -> void:
	if _sprite_radius <= 0.0:
		return

	var factor := _current_radius / _sprite_radius
	anim.scale = _base_anim_scale * factor

func _on_anim_finished() -> void:
	if not is_queued_for_deletion():
		explosion.stop()
		queue_free()
