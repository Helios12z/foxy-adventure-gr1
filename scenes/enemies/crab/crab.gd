extends EnemyCharacter

@export var minion_health: int = 75

@onready var hurt_area = $Direction/HurtArea2D
@onready var summon_effect: AnimatedSprite2D = $Direction/SummonEffect
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

var _spawn_old_speed := 0.0
var _blink_tw: Tween

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
func play_spawn_intro(total: float = 0.6, times: int = 6, color: Color = Color8(255, 200, 64, 255)) -> void:
	_spawn_old_speed = movement_speed
	movement_speed = 0.0
	velocity.x = 0.0

	change_animation("cast")

	_play_summon_effect(total)
	_begin_spawn_blink(total, times, color)

	var tw := create_tween()
	tw.tween_interval(total)
	tw.tween_callback(Callable(self, "_end_spawn_intro"))

func _end_spawn_intro() -> void:
	_end_spawn_blink()
	_stop_summon_effect()

	movement_speed = _spawn_old_speed
	fsm.change_state(fsm.states.walk)

func _begin_spawn_blink(total: float, times: int, color: Color) -> void:
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

func _end_spawn_blink() -> void:
	if is_instance_valid(_blink_tw):
		_blink_tw.kill()
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_amount", 0.0)
		
func _play_summon_effect(total: float) -> void:
	if summon_effect == null:
		return
	summon_effect.visible = true
	summon_effect.play("default")
	summon_effect.frame = 0

	var frames := summon_effect.sprite_frames.get_frame_count("default")
	var fps = max(summon_effect.sprite_frames.get_animation_speed("default"), 0.001)
	var base_duration = frames / fps
	if base_duration > 0.0:
		summon_effect.speed_scale = base_duration / total
	else:
		summon_effect.speed_scale = 1.0

func _stop_summon_effect() -> void:
	if summon_effect == null:
		return
	summon_effect.visible = false
	summon_effect.stop()
	summon_effect.frame = 0
	summon_effect.speed_scale = 1.0
