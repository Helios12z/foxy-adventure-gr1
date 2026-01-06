extends EnemyState

var attack_sound_played: bool = false
var collision_enabled: bool = false

func _enter() -> void:
	obj.velocity.x = 0
	obj.change_animation("attack")
	obj.animated_sprite_2d.frame = 0
	obj.attack_collision_shape_2d.disabled = true
	attack_sound_played = false
	collision_enabled = false
	timer = obj.range_attack_windup_time

func _update(_delta: float) -> void:
	var current_frame = obj.animated_sprite_2d.frame

	if current_frame >= 6 and not collision_enabled:
		obj.attack_collision_shape_2d.disabled = false
		collision_enabled = true
		if not attack_sound_played:
			obj.attack.play(0.25)
			attack_sound_played = true

	if current_frame >= 9:
		obj.attack.stop()
		obj.attack_collision_shape_2d.disabled = true
		attack_sound_played = false

	if not obj.animated_sprite_2d.is_playing():
		obj.attack_collision_shape_2d.disabled = true
		change_state(fsm.states.idle)
