extends CharacterBody2D

var gravity: float = 900.0
var bounce_damping: float = 0.6
var friction: float = 0.8
var bounces: int = 0
var max_bounces: int = 3
var stop_threshold: float = 50.0

@onready var sprite = $Sprite2D
var angular_velocity: float = 0.0

func _ready():
	_setup_shader()
	
	# Randomize spin direction and speed (-4 to 4 radians/sec roughly)
	angular_velocity = randf_range(-4.0, 4.0)

func _physics_process(delta):
	velocity.y += gravity * delta
	
	# Spin effect (like particle)
	rotation += angular_velocity * delta
	
	# Store velocity before collision to calculate bounce
	var pre_collision_velocity = velocity
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	# Check for floor impact
	# Since move_and_slide zeros out velocity on collision, we use pre_collision_velocity
	# We also check collision count in case is_on_floor() is unreliable in first frame
	if is_on_floor():
		# If we hit the floor hard enough
		if bounces < max_bounces and abs(pre_collision_velocity.y) > stop_threshold:
			velocity.y = -pre_collision_velocity.y * bounce_damping
			velocity.x = pre_collision_velocity.x * friction
			angular_velocity *= friction # Slow down spin on bounce
			bounces += 1
			_do_bounce_deform()
		elif bounces >= max_bounces or abs(pre_collision_velocity.y) <= stop_threshold:
			# Stop moving and spinning
			velocity = Vector2.ZERO
			angular_velocity = 0.0 
			set_physics_process(false)
			
			# Ensure we end upright-ish or just lie there? 
			# User said: "biến mất mượt mà".
			# Let's just fade out after a short rest.
			_fade_out()

func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(queue_free)

# =======================================================
# SHADER LOGIC (Copied from Pearl Fairy Dead State)
# =======================================================

func _do_bounce_deform():
	# Impact Squash Effect
	var tw = create_tween()
	if tw:
		# Squash down immediately
		_set_deform(-0.15) 
		# Tween to stretch (bounce up) - Fast
		tw.tween_method(_set_deform, -0.15, 0.08, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		# Tween back to normal - Slower
		tw.tween_method(_set_deform, 0.08, 0.0, 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _setup_shader():
	if sprite:
		# Ensure we use an absolute path or correct relative path. 
		# Assuming res://scenes/enemies/pearl_fairy/pearl_fairy_deform.gdshader exists
		var shader = load("res://scenes/enemies/pearl_fairy/pearl_fairy_deform.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("pivot_offset_y", 0.5) # Pivot at bottom
		mat.set_shader_parameter("deform_y", 0.0)
		sprite.material = mat

func _set_deform(val: float):
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("deform_y", val)
