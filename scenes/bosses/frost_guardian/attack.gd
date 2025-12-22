extends EnemyState

var attacked: bool = false 
var attack_sound_played: bool = false 

func _enter() -> void:
	obj.velocity.x = 0
	obj.change_animation("attack")
	obj.attack_collision_shape_2d.disabled = true
	timer = obj.attack_cooldown

func _update(_delta: float) -> void:
	if attacked: 
		if update_timer(_delta):
			attacked = false 
		else: 
			return 
	
	var current_frame = obj.animated_sprite_2d.frame
	
	if current_frame >= 6:
		obj.attack_collision_shape_2d.disabled = false
		if not attack_sound_played: 
			obj.attack.play(0.25)
			attack_sound_played = true 
		
	if current_frame >= 9:
		obj.attack_collision_shape_2d.disabled = true
		attack_sound_played = false 

	if not obj.animated_sprite_2d.is_playing():
		attacked = true 
		obj.attack_collision_shape_2d.disabled = true
		change_state(fsm.states.idle)
