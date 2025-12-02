extends StaticBody2D

@export var visible_duration: float = 4.0
@export var hidden_duration: float = 2.0
@export var blink_duration: float = 1.5
@export var blink_speed: float = 6.0
@export var blink_alpha_min: float = 0.4
@export var blink_alpha_max: float = 1.0

# Bobbing (floating) settings
@export var bob_amplitude: float = 3.0 # biên độ dịch chuyển theo trục Y (pixels)
@export var bob_frequency: float = 0.5  # tần số mục tiêu (Hz)
@export var bob_accel: float = 60.0     # gia tốc hướng tới mục tiêu (cảm giác quán tính)
@export var bob_damping: float = 3.0    # suy giảm vận tốc (ma sát)

# Spring deform settings when player enters
@export var deform_strength: float = 0.08  # tỉ lệ biến dạng (8%)
@export var deform_in_time: float = 0.25   # thời gian nén
@export var deform_out_time: float = 0.35  # thời gian hồi

@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var detect_area: Area2D = $DetectArea if has_node("DetectArea") else null

var blinking: bool = false
var blink_elapsed: float = 0.0
var cycling: bool = false

# Bobbing state
var base_y: float
var bob_time: float = 0.0
var current_offset: float = 0.0
var offset_vel: float = 0.0

# Deform state
var base_sprite_scale: Vector2
var deform_tween: Tween

func _ready() -> void:
	sprite.modulate.a = 1.0
	if collider:
		collider.disabled = false
	visible = true
	set_process(true)
	base_y = position.y
	base_sprite_scale = sprite.scale
	if detect_area != null:
		detect_area.body_entered.connect(_on_detect_area_body_entered)
	# Không tự động vòng lặp; chờ người chơi kích hoạt

func _process(delta: float) -> void:
	if blinking and sprite:
		blink_elapsed += delta
		var mid := (blink_alpha_min + blink_alpha_max) * 0.5
		var amp := (blink_alpha_max - blink_alpha_min) * 0.5
		var alpha := mid + amp * sin(blink_elapsed * blink_speed)
		sprite.modulate.a = clamp(alpha, 0.0, 1.0)

	# Bobbing movement with inertia (spring-like)
	bob_time += delta
	var target_offset := sin(bob_time * TAU * bob_frequency) * bob_amplitude
	var error := target_offset - current_offset
	offset_vel += error * bob_accel * delta
	offset_vel *= max(0.0, 1.0 - bob_damping * delta)
	current_offset += offset_vel * delta
	position.y = base_y + current_offset

func _run_cycle() -> void:
	if cycling:
		return
	cycling = true
	# Bắt đầu nhấp nháy trong một khoảng thời gian
	blinking = true
	blink_elapsed = 0.0
	await get_tree().create_timer(blink_duration).timeout

	# Mờ dần rồi biến mất
	blinking = false
	if sprite:
		var t_out := create_tween()
		t_out.tween_property(sprite, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t_out.finished
	if collider:
		collider.disabled = true
	visible = false

	# Ẩn trong một khoảng thời gian rồi xuất hiện trở lại
	await get_tree().create_timer(hidden_duration).timeout

	# Xuất hiện trở lại với mờ dần vào và reset trạng thái
	visible = true
	if sprite:
		sprite.modulate.a = 0.0
		var t_in := create_tween()
		t_in.tween_property(sprite, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t_in.finished
	if collider:
		collider.disabled = false
	cycling = false

func _on_detect_area_body_entered(body: Node) -> void:
	if body is Player:
		_play_spring_deform()
		# Khi người chơi đứng lên mây mới kích hoạt chu kỳ nhấp nháy/biến mất
		_run_cycle()

func _play_spring_deform() -> void:
	if deform_tween != null and deform_tween.is_running():
		deform_tween.kill()
	var target_scale := Vector2(
		base_sprite_scale.x * (1.0 + deform_strength),
		base_sprite_scale.y * (1.0 - deform_strength)
	)
	deform_tween = create_tween()
	deform_tween.tween_property(sprite, "scale", target_scale, deform_in_time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	deform_tween.tween_property(sprite, "scale", base_sprite_scale, deform_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
