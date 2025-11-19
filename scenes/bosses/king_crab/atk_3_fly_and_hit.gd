extends KingCrabState

enum { HOVER, DASH, IMPACT }
var phase := HOVER
var hover_timer := 0.0
var hover_y := 0.0
var start_x := 0.0

var blink_color_start: Color = Color8(255, 200, 64, 255)   
var blink_times_windup := 6
var _blink_tw: Tween

func _enter()->void:
	obj.change_animation("atk3_fly_and_hit")
	start_x = obj._atk3_liftoff_x
	hover_y = obj._atk3_drop_target.y - obj.atk3_fly_height
	obj.global_position = Vector2(start_x, hover_y)
	phase = HOVER
	hover_timer = obj.atk3_hover_time
	play_attack_effect(5, hover_timer)
	_begin_cast_blink(hover_timer, blink_times_windup, blink_color_start)

func _update(d: float)->void:
	match phase:
		HOVER:
			obj.global_position = Vector2(start_x, hover_y)
			hover_timer -= d
			if hover_timer <= 0.0:
				disable_attack_effect()
				_end_cast_blink()
				phase = DASH

		DASH:
			var target = obj._atk3_drop_target
			var to_target = target - obj.global_position
			var dist = to_target.length()

			if dist <= 2.0:
				obj.global_position = target
				_do_impact()
				return

			var dir = to_target / max(dist, 0.001)
			var step = dir * obj.atk3_dash_speed * d

			if step.length() >= dist:
				obj.global_position = target
				_do_impact()
			else:
				obj.global_position += step

		IMPACT:
			change_state(fsm.states.idle) 
			return

func _do_impact() -> void:
	_snap_to_ground() 
	_end_fly_mode()
	obj._chain_after_basic = false
	phase = IMPACT
	
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
