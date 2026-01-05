extends EnemyState

const MAX_BOUNCES = 2
var bounces = 0
var bounce_force = 250.0

func _enter():
	obj.change_animation("dead")
	obj.gravity = 900
	obj.velocity.x = 0
	obj.set_hurt_collision(false)
	obj.set_hit_collision(false)
	obj.disable_check_player_in_sight()
	obj.drop_coins()
	
	bounces = 0
	timer = 0.0 # Don't start disappear timer yet
	
	_setup_shader()

func _update(delta):
	# Bounce logic
	if obj.is_on_floor():
		if bounces < MAX_BOUNCES:
			_do_bounce()
			bounces += 1
		else:
			obj.velocity.x = 0
			if timer == 0.0:
				timer = 1.0 # Disappear after 1 second of resting

	if timer > 0.0:
		if update_timer(delta):
			obj.queue_free()

func _do_bounce():
	obj.velocity.y = -bounce_force
	bounce_force *= 0.5
	
	# Impact Squash Effect
	# Only create tween if node is valid
	if obj and is_instance_valid(obj):
		var tw = obj.create_tween()
		if tw:
			# Squash down immediately (set value)
			_set_deform(-0.1)
			# Tween to stretch (bounce up) - Fast
			tw.tween_method(_set_deform, -0.1, 0.05, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			# Tween back to normal - Slower
			tw.tween_method(_set_deform, 0.05, 0.0, 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _setup_shader():
	if obj.animated_sprite:
		var shader = load("res://scenes/enemies/pearl_fairy/pearl_fairy_deform.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("pivot_offset_y", 0.5) # Pivot at bottom
		mat.set_shader_parameter("deform_y", 0.0)
		obj.animated_sprite.material = mat

func _set_deform(val: float):
	if obj.animated_sprite and obj.animated_sprite.material:
		obj.animated_sprite.material.set_shader_parameter("deform_y", val)
