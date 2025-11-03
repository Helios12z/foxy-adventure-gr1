extends PlayerState

var dash_duration: float = 0.15
var dash_speed: float = 800.0
var ghost_interval: float = 0.03
var _elapsed: float = 0.0
var _last_ghost: float = 0.0

func _enter() -> void:
	# Keep current animation; just start dash movement
	timer = obj.dash_duration
	# Flatten vertical movement for a clean dash
	obj.velocity.y = 0
	obj.set_ignore_gravity(true)
	obj.register_dash_started()
	# Enable dash warp shader effect
	var mat: Material = null
	if obj.animated_sprite != null:
		mat = obj.animated_sprite.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("warp", 1.8)
		mat.set_shader_parameter("squash", 0.9)
		mat.set_shader_parameter("dir", float(obj.direction))
	# Spawn an immediate afterimage at dash start
	_spawn_afterimage()

func _update(delta: float) -> void:
	# Apply fast horizontal motion in facing direction
	obj.velocity.x = obj.dash_speed * obj.direction
	# Keep shader direction in sync while dashing
	var mat: Material = null
	if obj.animated_sprite != null:
		mat = obj.animated_sprite.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("dir", float(obj.direction))
	_elapsed += delta
	if _elapsed - _last_ghost >= obj.dash_ghost_interval:
		_spawn_afterimage()
		_last_ghost = _elapsed
	# End dash when timer finishes
	if update_timer(delta):
		obj.velocity.x = 0
		change_state(fsm.states.idle)

func _exit() -> void:
	# Ensure velocity resets when exiting dash
	obj.velocity.x = 0
	obj.set_ignore_gravity(false)
	obj.register_dash_finished()
	# Disable dash warp shader effect
	var mat: Material = null
	if obj.animated_sprite != null:
		mat = obj.animated_sprite.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("warp", 0.0)
		mat.set_shader_parameter("squash", 0.0)

func _spawn_afterimage() -> void:
	var dir_node: Node2D = obj.get_node("Direction")
	var source: AnimatedSprite2D = obj.animated_sprite
	if dir_node == null or source == null:
		return
	# Container sits in world space to avoid following the player
	var container := Node2D.new()
	# Add to scene first, then set as toplevel to avoid inheriting parent transforms
	obj.get_parent().add_child(container)
	container.set_as_top_level(true)
	container.global_position = dir_node.global_position - Vector2(4 * obj.direction, 14)
	container.scale = dir_node.scale
	# Duplicate current sprite frame as an afterimage
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = source.sprite_frames
	ghost.animation = source.animation
	ghost.frame = source.frame
	ghost.stop()
	ghost.modulate = Color(1, 1, 1, 0.6)
	container.add_child(ghost)
	# Fade out quickly, then free
	var tw := container.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tw.tween_callback(Callable(container, "queue_free"))
