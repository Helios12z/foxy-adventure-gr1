extends EnemyState

var phase := 0
var t := 0.0

var windup_duration := 0.8         
var post_pause := 0.35            

var summon_blink_color_start: Color = Color8(255, 200, 64, 255)   
var summon_blink_color_end:   Color = Color8(255, 255, 255, 255) 
var blink_times_windup := 6
var blink_times_post := 4

var _blink_tw: Tween

func _enter() -> void:
	phase = 0
	t = 0.0
	obj.velocity.x = 0.0
	obj.change_animation("cast")
	_begin_summon_blink(windup_duration, blink_times_windup, summon_blink_color_start)

func _update(delta: float) -> void:
	t += delta
	match phase:
		0:
			if t >= windup_duration:
				t = 0.0
				_end_summon_blink()
				obj._disable_attack_effect()

				if obj.has_method("spawn_minions"):
					obj.spawn_minions()

				_begin_summon_blink(post_pause, blink_times_post, summon_blink_color_end)
				phase = 1

		1:
			if t >= post_pause:
				_finish_summon()

func _exit() -> void:
	_end_summon_blink()
	obj._disable_attack_effect()

func _finish_summon() -> void:
	_end_summon_blink()
	obj._disable_attack_effect()
	change_state(fsm.states.idle)

func _begin_summon_blink(total: float, times := 6, color := Color(1, 0.8, 0.2, 1)) -> void:
	var mat := obj.animated_sprite_2d.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 0.0)

	if is_instance_valid(_blink_tw):
		_blink_tw.kill()

	_blink_tw = obj.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step = max(total / float(times * 2), 0.01)
	for i in times:
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)

func _end_summon_blink() -> void:
	if is_instance_valid(_blink_tw):
		_blink_tw.kill()
	var mat := obj.animated_sprite_2d.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_amount", 0.0)
