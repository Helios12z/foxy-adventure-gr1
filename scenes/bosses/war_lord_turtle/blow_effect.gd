extends Node2D

@export var damage: int = 50
@export var initial_radius: float = 20.0
@export var max_radius: float = 240.0

var _base_anim_scale: Vector2
var _sprite_radius: float = 1.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area_2d: HitArea2D = $HitArea2D
@onready var circle_shape: CircleShape2D = $HitArea2D/CollisionShape2D.shape as CircleShape2D


func _ready() -> void:
	hit_area_2d.damage = damage

	_base_anim_scale = anim.scale

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

	circle_shape.radius = initial_radius
	_update_visual_scale(initial_radius)

	anim.frame = 0
	anim.play()

	anim.frame_changed.connect(_on_frame_changed)
	anim.animation_finished.connect(_on_anim_finished)


func _on_frame_changed() -> void:
	if anim.sprite_frames == null:
		return

	var anim_name := anim.animation
	if anim_name == "":
		return

	var frame_count := anim.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 1:
		return

	var t := float(anim.frame) / float(frame_count - 1)
	var radius = lerp(initial_radius, max_radius, t)

	circle_shape.radius = radius
	_update_visual_scale(radius)


func _update_visual_scale(radius: float) -> void:
	if _sprite_radius <= 0.0:
		return

	var factor := radius / _sprite_radius
	anim.scale = _base_anim_scale * factor


func _on_anim_finished() -> void:
	if not is_queued_for_deletion():
		queue_free()
