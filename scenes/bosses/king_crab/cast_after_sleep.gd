extends KingCrabState

var summon_blink_color_start: Color = Color8(255, 200, 64, 255)   
var summon_blink_color_end:   Color = Color8(255, 255, 255, 255) 
var blink_times_windup := 6
var blink_times_post := 4

var _blink_tw: Tween

func _enter() -> void:
	obj.change_animation("cast")
	obj.cast.play()
	_begin_blink(4.0, 6)
	
func _update( _delta ):
	if obj.seen_player:
		change_state(fsm.states.idle)
		
func _exit() -> void:
	_end_blink()
		
func _begin_blink(total: float, times := 6, color := Color(1, 0.8, 0.2, 1)) -> void:
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

func _end_blink() -> void:
	if is_instance_valid(_blink_tw):
		_blink_tw.kill()
	var mat := obj.animated_sprite_2d.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_amount", 0.0)
