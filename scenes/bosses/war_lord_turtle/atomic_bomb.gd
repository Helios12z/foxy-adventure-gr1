extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D              
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D  
@onready var hit_area_2d: HitArea2D = $HitArea2D
@onready var collision_shape_2d: CollisionShape2D = $HitArea2D/CollisionShape2D
@onready var rect_shape: RectangleShape2D = $HitArea2D/CollisionShape2D.shape as RectangleShape2D
@onready var explosion: AudioStreamPlayer2D = $Explosion
@onready var sound: AudioStreamPlayer2D = $Sound

@export var damage: int = 300
@export var explode_time: float = 2.75
@export var fall_speed: float = 80.0              
@export var hide_bomb_frame: int = 13              

var _elapsed: float = 0.0
var _exploding: bool = false

var _base_anim_scale: Vector2
var _fallback_extents: Vector2 = Vector2(64.0, 64.0)

func _ready() -> void:
	hit_area_2d.damage = damage
	sound.play()

	sprite_2d.visible = true
	animated_sprite_2d.stop()
	animated_sprite_2d.frame = 0
	animated_sprite_2d.visible = false

	hit_area_2d.monitoring = false
	hit_area_2d.monitorable = false

	_base_anim_scale = animated_sprite_2d.scale
	_fallback_extents = Vector2(64.0, 64.0)

	if animated_sprite_2d.sprite_frames != null:
		var anim_name := animated_sprite_2d.animation
		if anim_name == "":
			var names := animated_sprite_2d.sprite_frames.get_animation_names()
			if names.size() > 0:
				anim_name = names[0]

		if anim_name != "":
			var tex := animated_sprite_2d.sprite_frames.get_frame_texture(anim_name, 0)
			if tex != null:
				var w := tex.get_width() * _base_anim_scale.x
				var h := tex.get_height() * _base_anim_scale.y
				_fallback_extents = Vector2(w, h) * 0.5

	if rect_shape:
		rect_shape.extents = Vector2.ZERO

	animated_sprite_2d.frame_changed.connect(_on_explosion_frame_changed)
	animated_sprite_2d.animation_finished.connect(_on_explosion_finished)

func _physics_process(delta: float) -> void:
	if not _exploding:
		_elapsed += delta
		global_position.y += fall_speed * delta

		if _elapsed >= explode_time:
			_start_explosion()

func _start_explosion() -> void:
	if _exploding:
		return
	_exploding = true

	animated_sprite_2d.visible = true
	animated_sprite_2d.frame = 0

	if animated_sprite_2d.sprite_frames != null and animated_sprite_2d.animation == "":
		var names := animated_sprite_2d.sprite_frames.get_animation_names()
		if names.size() > 0:
			animated_sprite_2d.animation = names[0]

	animated_sprite_2d.play()

	hit_area_2d.monitoring = false
	hit_area_2d.monitorable = false

func _on_explosion_frame_changed() -> void:
	if not _exploding:
		return  

	var frame := animated_sprite_2d.frame

	if frame == hide_bomb_frame and sprite_2d.visible:
		sprite_2d.visible = false
		explosion.play()
		sound.stop()
		hit_area_2d.monitoring = true
		hit_area_2d.monitorable = true

	if hit_area_2d.monitoring:
		_update_hit_rect_for_current_frame()

func _update_hit_rect_for_current_frame() -> void:
	if rect_shape == null:
		return

	var sf := animated_sprite_2d.sprite_frames
	if sf == null:
		rect_shape.extents = _fallback_extents
		return

	var anim_name := animated_sprite_2d.animation
	if anim_name == "":
		return

	var tex := sf.get_frame_texture(anim_name, animated_sprite_2d.frame)
	if tex == null:
		rect_shape.extents = _fallback_extents
		return

	var w := tex.get_width() * animated_sprite_2d.scale.x
	var h := tex.get_height() * animated_sprite_2d.scale.y
	rect_shape.extents = Vector2(w, h) * 0.5

func _on_explosion_finished() -> void:
	if not is_queued_for_deletion():
		explosion.stop()
		queue_free()
