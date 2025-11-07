extends EnemyState

var teleport_phase := 0 
var fade_timer := 0.0
var fade_duration := 0.5

func _enter() -> void:
	obj.change_animation("idle")
	teleport_phase = 0
	fade_timer = 0.0
	obj.velocity.x = 0.0
	
	obj.play_teleport_effect(fade_duration)

func _update(d: float) -> void:
	fade_timer += d
	
	if teleport_phase == 0:  
		var progress = min(fade_timer / fade_duration, 1.0)
		obj.animated_sprite_2d.modulate.a = 1.0 - progress
		
		if fade_timer >= fade_duration:
			teleport_phase = 1
			fade_timer = 0.0
			_teleport_to_new_position()
	
	elif teleport_phase == 1: 
		if fade_timer >= 0.2:
			teleport_phase = 2
			fade_timer = 0.0
			obj._disable_teleport_effect()
	
	elif teleport_phase == 2:  # Fade in
		var progress = min(fade_timer / fade_duration, 1.0)
		obj.animated_sprite_2d.modulate.a = progress
		
		if fade_timer >= fade_duration:
			_finish_teleport()

func _teleport_to_new_position() -> void:
	if obj.found_player == null:
		return
	
	var player_x = obj.found_player.global_position.x
	var current_x = obj.global_position.x
	
	var safe_distance = randf_range(200.0, 400.0)
	
	var go_left = randf() > 0.5
	
	if player_x < current_x:
		go_left = randf() > 0.3  # 30% sang trái, 70% sang phải
	else:
		go_left = randf() < 0.7  # 70% sang trái, 30% sang phải
	
	var new_x: float
	if go_left:
		new_x = player_x - safe_distance
	else:
		new_x = player_x + safe_distance
	
	new_x = clamp(new_x, 100.0, 1900.0)
	
	obj.global_position.x = new_x
	
	var direction_to_player = sign(player_x - new_x)
	if direction_to_player != 0:
		obj.change_direction(int(direction_to_player))

func _finish_teleport() -> void:
	obj.animated_sprite_2d.modulate.a = 1.0
	obj.reset_proximity_timer()  
	change_state(fsm.states.walk)

func _exit() -> void:
	obj.animated_sprite_2d.modulate.a = 1.0
	obj._disable_teleport_effect()  
