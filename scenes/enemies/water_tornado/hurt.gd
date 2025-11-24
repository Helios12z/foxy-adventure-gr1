extends WarlordTurtleState

var _blink_tw: Tween

func _enter() -> void:
	if obj.health <= 0:
		fsm.change_state(fsm.states.dead)
	_start_hurt_blink()

func _update(_delta: float) -> void:
	if not is_instance_valid(_blink_tw) or not _blink_tw.is_running():
		_stop_blink()
		change_state(fsm.previous_state)

func _start_hurt_blink() -> void:
	var mat := obj.water.material as ShaderMaterial
	if mat == null:
		return

	if is_instance_valid(_blink_tw):
		_blink_tw.kill()

	mat.set_shader_parameter("flash_color", Color(1.0, 0.3, 0.3, 1.0))
	mat.set_shader_parameter("flash_amount", 0.0)

	_blink_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var step := 0.05
	for i in range(3):
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)

func _stop_blink() -> void:
	if is_instance_valid(_blink_tw):
		_blink_tw.kill()
	var mat := obj.water.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_amount", 0.0)
