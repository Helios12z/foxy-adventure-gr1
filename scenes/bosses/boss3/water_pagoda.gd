extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit: HitArea2D       = $HitArea2D
@onready var pagoda_sound: AudioStreamPlayer = $WaterPagodaSound

@export var telegraph_time := 0.6  # thời gian cho player thấy "appears" để né
@export var active_time    := 0.4  # thời gian hitbox mở khi "slash"
@export var auto_free      := true # xong thì tự huỷ

@export var ghost_interval: float = 0.06
var _elapsed: float = 0.0
var _last_ghost: float = 0.0
var _falling: bool = false

func _ready() -> void:
	# Mặc định tắt hitbox
	hit.set_deferred("monitoring", false)
	# hit.set_deferred("monitorable", false)
	# hit.set_deferred("monitorable", false)
	anim.visible = false

func _process(delta: float) -> void:
	if _falling:
		_elapsed += delta
		if _elapsed - _last_ghost >= ghost_interval:
			_spawn_afterimage()
			_last_ghost = _elapsed


# Gọi khi spawn, đặt nó tại vị trí player
func cast_at(target_position: Vector2) -> void:
	global_position = target_position
	await _run_sequence()


# Nếu bạn vẫn muốn giữ tên play() để Boss gọi group
func play() -> void:
	await _run_sequence()


# For falling pagoda behavior - make visible while falling
func show_while_falling() -> void:
	anim.visible = true
	anim.play("appears")
	_falling = true


func _run_sequence() -> void:
	_falling = false
	print("[WaterPagoda] TELEGRAPH at ", global_position)

	# TELEGRAPH: hiện dần với anim "appears", chưa gây dmg
	anim.visible = true
	anim.play("appears")

	# Check if still in tree before awaiting
	if not is_inside_tree():
		return

	await get_tree().create_timer(telegraph_time).timeout
	print("[WaterPagoda] TELEGRAPH_END")

	# Check if still valid after await
	if not is_inside_tree():
		return

	# ACTIVE: chuyển sang anim "slash", bật hitbox
	print("[WaterPagoda] ACTIVE_START (slash)")
	anim.play("slash")

	# Play pagoda sound when attacking
	if pagoda_sound:
		pagoda_sound.play()

	hit.set_deferred("monitoring", true)
	# hit.set_deferred("monitorable", true)

	# Check if still in tree before awaiting
	if not is_inside_tree():
		return

	await get_tree().create_timer(active_time).timeout
	print("[WaterPagoda] ACTIVE_END")

	# Check if still valid after await
	if not is_inside_tree():
		return

	# Kết thúc: tắt hitbox, tuỳ chọn huỷ node
	hit.set_deferred("monitoring", false)
	# hit.set_deferred("monitorable", false)

	if auto_free:
		print("[WaterPagoda] QUEUE_FREE")
		queue_free()
	else:
		anim.stop()
		anim.visible = false

func _spawn_afterimage() -> void:
	if anim == null:
		return
	var container := Node2D.new()
	# Add to the current scene so it stays in world space
	var root := get_tree().current_scene
	if root == null:
		return
	root.add_child(container)
	container.set_as_top_level(true)
	container.global_position = anim.global_position
	# Match visual scale
	container.scale = anim.global_scale
	# Ensure afterimage renders above environment/FX like fire_ball
	container.z_index = 100
	
	var ghost := AnimatedSprite2D.new()
	if anim.sprite_frames != null:
		ghost.sprite_frames = anim.sprite_frames
	ghost.animation = anim.animation
	ghost.frame = anim.frame
	ghost.stop()
	ghost.modulate = Color(1, 1, 1, 0.6)
	ghost.light_mask = 2
	
	# Use global rotation to match orientation
	ghost.rotation = anim.global_rotation
	ghost.z_index = 100
	
	container.add_child(ghost)
	var tw := container.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_callback(Callable(container, "queue_free"))
