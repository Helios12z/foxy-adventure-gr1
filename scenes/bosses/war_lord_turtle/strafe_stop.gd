extends WarlordTurtleState

var _connected: bool = false

func _enter() -> void:
	obj.change_animation("strafe_stop")

	var anim = obj.animated_sprite_2d
	if anim and not anim.animation_finished.is_connected(_on_strafe_stop_finished):
		anim.animation_finished.connect(_on_strafe_stop_finished)
		_connected = true


func _exit() -> void:
	var anim = obj.animated_sprite_2d
	if anim and _connected and anim.animation_finished.is_connected(_on_strafe_stop_finished):
		anim.animation_finished.disconnect(_on_strafe_stop_finished)
	_connected = false


func _update(_delta: float) -> void:
	pass


func _on_strafe_stop_finished() -> void:
	if fsm.current_state != self:
		return
	if obj.animated_sprite_2d.animation != "strafe_stop":
		return

	change_state(fsm.states.stun)
