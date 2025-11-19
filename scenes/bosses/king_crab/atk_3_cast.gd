extends KingCrabState

var blink_color_start: Color = Color8(255, 200, 64, 255)   
var blink_times_windup := 6
var _blink_tw: Tween

func _enter()->void:
	disable_attack_effect()
	obj.change_animation("cast")
	timer = obj.atk3_cast_time
	_begin_cast_blink(timer, blink_times_windup, blink_color_start)
	play_attack_effect(3, timer)
	_begin_fly_mode()
	obj._atk3_liftoff_x = obj.global_position.x

func _update(d: float)->void:
	if update_timer(d):
		disable_attack_effect()
		_end_cast_blink()
		change_state(fsm.states.atk3_windup)
		
func _begin_cast_blink(total: float, times := 6, color := Color(1, 0.8, 0.2, 1)) -> void:
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

func _end_cast_blink() -> void:
	if is_instance_valid(_blink_tw):
		_blink_tw.kill()
	var mat := obj.animated_sprite_2d.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_amount", 0.0)
