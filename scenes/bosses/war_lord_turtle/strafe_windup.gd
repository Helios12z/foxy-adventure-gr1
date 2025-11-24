extends WarlordTurtleState

var _connected: bool = false

func _enter() -> void:
	obj.change_animation("strafe_windup")

	var anim = obj.animated_sprite_2d
	if anim and not anim.animation_finished.is_connected(_on_windup_finished):
		anim.animation_finished.connect(_on_windup_finished)
		_connected = true

func _exit() -> void:
	var anim = obj.animated_sprite_2d
	if anim and _connected and anim.animation_finished.is_connected(_on_windup_finished):
		anim.animation_finished.disconnect(_on_windup_finished)
	_connected = false

func _on_windup_finished() -> void:
	if fsm.current_state != self:
		return
	if obj.animated_sprite_2d.animation != "strafe_windup":
		return
	change_state(fsm.states.strafe)
