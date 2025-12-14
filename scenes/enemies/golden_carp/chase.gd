extends EnemyState

@export var chase_speed = 150
@export var ghost_interval: float = 0.05

var _elapsed: float = 0.0
var _last_ghost: float = 0.0

func _enter() -> void:
	obj.change_animation("walk")
	_elapsed = 0.0
	_last_ghost = 0.0

func _update(delta: float) -> void:

	if obj.can_detect_player():
		obj.velocity.x = obj.direction * chase_speed

		_elapsed += delta
		if _elapsed - _last_ghost >= ghost_interval:
			_spawn_afterimage()
			_last_ghost = _elapsed

		if obj.is_in_attack_scope():
			change_state(fsm.states.attack)
	else:
		change_state(fsm.states.walk)

func _spawn_afterimage() -> void:
	var dir_node: Node2D = obj.get_node("Direction")
	var source: AnimatedSprite2D = obj.animated_sprite_2d
	if dir_node == null or source == null:
		return
	
	var container := Node2D.new()
	# Add to scene root
	obj.get_parent().add_child(container)
	container.set_as_top_level(true)
	
	container.global_position = dir_node.global_position
	container.scale = dir_node.scale
	
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = source.sprite_frames
	ghost.animation = source.animation
	ghost.frame = source.frame
	ghost.position = source.position
	ghost.rotation = source.rotation
	ghost.scale = source.scale
	ghost.stop()
	ghost.modulate = Color(1, 1, 1, 0.5)
	ghost.light_mask = 2
	container.add_child(ghost)
	
	var tw := container.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tw.tween_callback(Callable(container, "queue_free"))
	
