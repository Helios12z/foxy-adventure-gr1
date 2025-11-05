extends PointLight2D

class_name FlickerLight2D

@export var energy_base: float = 0.8
@export var energy_variation: float = 0.12
@export var tex_size: int = 256
@export var tex_scale: float = 2.2
@export var shadow_on: bool = false
@export var blend_mode_val: int = Light2D.BLEND_MODE_ADD
@export var light_color: Color = Color(1.0, 0.92, 0.5)
@export var cull_mask: int = 1
@export var offset_px: Vector2 = Vector2(0, -40)
@export var auto_start: bool = true
@export var fade_in_time: float = 0.3
@export var fade_out_time: float = 0.25

var _fade: float = 1.0

func _ready():
	# Apply exported configuration
	self.texture_scale = tex_scale
	self.shadow_enabled = shadow_on
	self.blend_mode = blend_mode_val
	self.color = light_color
	self.range_item_cull_mask = cull_mask
	self.offset = offset_px
	# Procedural radial mask for smooth falloff
	self.texture = _make_radial_mask(tex_size)
	# Auto fade in if requested
	if auto_start:
		_fade = 0.0
		fade_in()

func _process(delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 200.0
	var e := energy_base + sin(t) * energy_variation
	self.energy = max(0.0, e * _fade)

func fade_in(time: float = -1.0) -> void:
	var dur := fade_in_time if time < 0.0 else time
	var tw := create_tween()
	tw.tween_property(self, "_fade", 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func fade_out(time: float = -1.0) -> void:
	var dur := fade_out_time if time < 0.0 else time
	var tw := create_tween()
	tw.tween_property(self, "_fade", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func set_texture_from_image(img: Image) -> void:
	self.texture = ImageTexture.create_from_image(img)

func _make_radial_mask(size: int) -> Texture2D:
	var s: int = max(size, 32)
	var img: Image = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(s * 0.5, s * 0.5)
	var max_dist: float = center.length()
	for y in range(s):
		for x in range(s):
			var p: Vector2 = Vector2(x, y)
			var d: float = (p - center).length() / max_dist
			var v: float = clamp(1.0 - d, 0.0, 1.0)
			# Smooth falloff
			v = v * v * (3.0 - 2.0 * v)
			img.set_pixel(x, y, Color(v, v, v, v))
	return ImageTexture.create_from_image(img)
