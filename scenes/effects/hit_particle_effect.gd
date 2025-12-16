class_name HitParticleEffect
extends Node2D

## Hit particle effect component - spawns particles when character is hit
## Can be used for both player and enemies

@export var enabled: bool = true
@export var particle_texture: Texture2D = null
@export var base_scale: float = 1.0
@export var particle_count: int = 8
@export var min_velocity: float = 100.0
@export var max_velocity: float = 250.0
@export var gravity_strength: float = 400.0
@export var rotation_speed_min: float = -5.0
@export var rotation_speed_max: float = 5.0
@export var lifetime_min: float = 0.5
@export var lifetime_max: float = 1.0
@export var fade_duration: float = 0.3
@export_range(0.0, 1.0) var particle_opacity: float = 1.0  # Độ mờ của particle (0.0 = trong suốt hoàn toàn, 1.0 = không trong suốt)
@export var reverse_direction: bool = true  # true = tung ngược hướng đánh, false = tung cùng hướng đánh

# Preload default particle texture
const DEFAULT_PARTICLE_TEXTURE = preload("res://asset/foxy/foxy/effects/hit_particle/hit_particle_bubble.png")

func _ready() -> void:
	# Use default texture if none is set
	if particle_texture == null:
		particle_texture = DEFAULT_PARTICLE_TEXTURE

## Spawn particles based on hit direction
## hit_direction: normalized direction of the attack (from attacker to victim)
func spawn_particles(hit_direction: Vector2) -> void:
	if not enabled or particle_texture == null:
		return
	
	# Calculate particle direction based on setting
	var normalized_hit_dir = hit_direction.normalized() if hit_direction.length() > 0.01 else Vector2.RIGHT
	var particle_direction = -normalized_hit_dir if reverse_direction else normalized_hit_dir
	
	for i in range(particle_count):
		_create_particle(particle_direction)

func _create_particle(base_direction: Vector2) -> void:
	var particle = Sprite2D.new()
	particle.texture = particle_texture
	particle.centered = true
	
	# Random scale variation (70% to 130% of base scale)
	var scale_variation = randf_range(0.7, 1.3) * base_scale
	particle.scale = Vector2(scale_variation, scale_variation)
	
	# Random rotation
	particle.rotation = randf_range(0, TAU)
	
	# Add to scene
	get_tree().current_scene.add_child(particle)
	particle.global_position = global_position
	
	# Calculate velocity with spread
	var spread_angle = randf_range(-PI/3, PI/3)  # ±60 degrees spread
	var direction = base_direction.rotated(spread_angle)
	var velocity_magnitude = randf_range(min_velocity, max_velocity)
	var velocity = direction * velocity_magnitude
	
	# Random rotation speed
	var rotation_speed = randf_range(rotation_speed_min, rotation_speed_max)
	
	# Random lifetime
	var lifetime = randf_range(lifetime_min, lifetime_max)
	
	# Animate particle
	_animate_particle(particle, velocity, rotation_speed, lifetime)

func _animate_particle(particle: Sprite2D, initial_velocity: Vector2, rotation_speed: float, lifetime: float) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Initial phase: Strong launch (first 20% of lifetime)
	var launch_duration = lifetime * 0.2
	var mid_duration = lifetime * 0.6
	var fade_out_duration = min(fade_duration, lifetime * 0.2)
	
	# Position animation with physics-like motion
	var current_pos = particle.global_position
	var velocity = initial_velocity
	
	# Create a custom animation using Timer + manual updates
	var physics_timer = Timer.new()
	physics_timer.wait_time = 0.016  # ~60 FPS
	physics_timer.one_shot = false
	particle.add_child(physics_timer)
	
	var elapsed_time = 0.0
	var current_velocity = velocity
	
	physics_timer.timeout.connect(func():
		if elapsed_time >= lifetime:
			physics_timer.stop()
			particle.queue_free()
			return
		
		var delta = physics_timer.wait_time
		elapsed_time += delta
		
		# Apply gravity
		current_velocity.y += gravity_strength * delta
		
		# Apply deceleration to horizontal velocity (friction)
		var friction_factor = 0.95
		current_velocity.x *= friction_factor
		
		# Update position
		particle.global_position += current_velocity * delta
		
		# Update rotation
		particle.rotation += rotation_speed * delta
	)
	
	physics_timer.start()
	
	# Fade in (smooth appearance)
	particle.modulate.a = 0.0
	tween.tween_property(particle, "modulate:a", particle_opacity, 0.1)
	
	# Fade out (smooth disappearance)
	tween.tween_property(particle, "modulate:a", 0.0, fade_out_duration).set_delay(lifetime - fade_out_duration)
	
	# Cleanup after lifetime
	tween.finished.connect(func():
		if is_instance_valid(particle):
			particle.queue_free()
	)
