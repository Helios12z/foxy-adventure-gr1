extends EnemyState

func _enter() -> void:
	obj.change_animation("appear")
	if not obj.boss_music.is_playing(): 
		obj.boss_music.play()

func _update(_delta: float) -> void:
	if obj.animated_sprite_2d.is_playing():
		pass
	else:
		change_state(fsm.states.idle)
