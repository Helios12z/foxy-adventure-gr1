extends Node2D

@export var cannon_scene: PackedScene
@export var cannon_move_speed: float = 200.0
@export var spike_damage: float = 70.0

@export var spawn_interval: float = 2.5
@export var lifetime: float = 12.5

@onready var marker_2d: Marker2D = $Marker2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sound: AudioStreamPlayer2D = $Sound

var _blink_tw: Tween
var _alive_time: float = 0.0
var _time_since_last_spawn: float = 0.0

func _ready() -> void:
	sound.play()
	_begin_blink(0.6, 4, Color(0.809, 0.579, 0.06, 1.0))
	add_to_group("warlord_portal")

func _physics_process(delta: float) -> void:
	_alive_time += delta
	_time_since_last_spawn += delta

	if _time_since_last_spawn >= spawn_interval:
		_time_since_last_spawn -= spawn_interval
		_spawn_cannon()

	if _alive_time >= lifetime and not is_queued_for_deletion():
		sound.stop()
		queue_free()

func _begin_blink(total: float, times: int, color: Color) -> void:
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 0.0)

	if is_instance_valid(_blink_tw):
		_blink_tw.kill()

	_blink_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step = max(total / float(times * 2), 0.01)
	for i in times:
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)


func _end_blink() -> void:
	if is_instance_valid(_blink_tw):
		_blink_tw.kill()
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_amount", 0.0)

func _spawn_cannon() -> void:
	if cannon_scene == null or marker_2d == null:
		return

	var b = cannon_scene.instantiate()
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(b)

	if b is Node2D:
		(b as Node2D).global_position = marker_2d.global_position

	var dir_vec := Vector2.DOWN

	if "move_speed" in b:
		b.move_speed = cannon_move_speed
	if "dir" in b:
		b.dir = dir_vec.normalized()
	if "spike_damage" in b:
		b.spike_damage = spike_damage
	if b.has_method("set_direction"):
		b.set_direction(-1 if dir_vec.x < 0.0 else 1)
