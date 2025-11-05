extends PlayerState

var dash_duration: float = 0.18
var dash_speed: float = 800.0
var dash_vertical_ratio: float = 0.6

var _elapsed: float = 0.0
var _last_ghost: float = 0.0
var _prev_material: Material = null

func _enter() -> void:
	# Thời lượng dash chéo
	timer = obj.dash_duration
	# Khoá trọng lực và đặt vận tốc chéo lên theo hướng hiện tại
	obj.set_ignore_gravity(true)
	obj.velocity.x = obj.dash_speed * obj.direction
	obj.velocity.y = -obj.dash_speed * dash_vertical_ratio
	obj.register_dash_started()

	# Áp dụng shader dash chéo
	_prev_material = null
	var shader := load("res://scenes/character/player/shaders/dash_diagonal.gdshader")
	if shader != null and obj.animated_sprite != null:
		_prev_material = obj.animated_sprite.material
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("warp", 1.4)
		mat.set_shader_parameter("squash", 0.6)
		mat.set_shader_parameter("lean", 0.5)
		mat.set_shader_parameter("diag_strength", 0.8)
		mat.set_shader_parameter("dir_x", float(obj.direction))
		mat.set_shader_parameter("dir_y", -1.0)
		obj.animated_sprite.material = mat

	# Spawn ảo ảnh ngay lúc bắt đầu
	_spawn_afterimage()

func _update(delta: float) -> void:
	# Duy trì vận tốc chéo ổn định
	obj.velocity.x = obj.dash_speed * obj.direction
	obj.velocity.y = -obj.dash_speed * dash_vertical_ratio

	# Đồng bộ hướng shader
	var mat: Material = null
	if obj.animated_sprite != null:
		mat = obj.animated_sprite.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("dir_x", float(obj.direction))

	_elapsed += delta
	if _elapsed - _last_ghost >= obj.dash_ghost_interval:
		_spawn_afterimage()
		_last_ghost = _elapsed

	# Kết thúc dash khi hết thời gian
	if update_timer(delta):
		# Thả ngang, cho rơi nếu đang trên không
		obj.velocity.x = 0
		change_state(fsm.states.idle if obj.is_on_floor() else fsm.states.fall)

func _exit() -> void:
	# Bật lại gravity, xoá hiệu ứng
	obj.set_ignore_gravity(false)
	obj.velocity.y = 0
	obj.register_dash_finished()
	var mat: Material = null
	if obj.animated_sprite != null:
		mat = obj.animated_sprite.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("warp", 0.0)
		mat.set_shader_parameter("squash", 0.0)
		mat.set_shader_parameter("lean", 0.0)
	if _prev_material != null and obj.animated_sprite != null:
		obj.animated_sprite.material = _prev_material

func _spawn_afterimage() -> void:
	var dir_node: Node2D = obj.get_node("Direction")
	var source: AnimatedSprite2D = obj.animated_sprite
	if dir_node == null or source == null:
		return
	var container := Node2D.new()
	# Add first and mark top-level so it stays in world space
	obj.get_parent().add_child(container)
	container.set_as_top_level(true)
	container.global_position = dir_node.global_position - Vector2(4 * obj.direction, 14)
	container.scale = dir_node.scale
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = source.sprite_frames
	ghost.animation = source.animation
	ghost.frame = source.frame
	ghost.stop()
	ghost.modulate = Color(1, 1, 1, 0.6)
	# Không cho afterimage bị ảnh hưởng bởi Light2D
	ghost.light_mask = 2
	container.add_child(ghost)
	var tw := container.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tw.tween_callback(Callable(container, "queue_free"))
