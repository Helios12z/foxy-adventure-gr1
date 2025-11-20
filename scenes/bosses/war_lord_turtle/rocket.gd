extends RigidBody2D

@export var speed: float = 80.0
@export var damage: int = 50
@export var arc_height: float = 150.0  

var target: Vector2
var _start_pos: Vector2
var _peak_y: float
var _phase: int = 0  
var _exploding := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea2D

# Cho boss gọi trực tiếp: m.init(target, speed, damage)
func init(p_target: Vector2, p_speed: float, p_damage: int) -> void:
	target = p_target
	speed = p_speed
	damage = p_damage

func _ready() -> void:
	gravity_scale = 0.0
	_start_pos = global_position

	if target == Vector2.ZERO:
		# Nếu chưa được set target thì bỏ
		queue_free()
		return

	_peak_y = min(_start_pos.y, target.y) - arc_height
	_phase = 1    # bắt đầu bay lên

	if hit_area:
		if hit_area.has_signal("body_entered"):
			hit_area.body_entered.connect(_on_hit_body_entered)
		if "damage" in hit_area:
			hit_area.damage = damage

func _physics_process(delta: float) -> void:
	match _phase:
		0:
			# chưa hoạt động
			linear_velocity = Vector2.ZERO
		1:
			# bay thẳng lên
			linear_velocity = Vector2(0.0, -speed)
			if global_position.y <= _peak_y:
				_phase = 2
				# tới đỉnh, nhảy x sang cột target
				global_position.x = target.x
		2:
			# rơi thẳng xuống target
			linear_velocity = Vector2(0.0, speed)
			if global_position.y >= target.y:
				explode()

# ---------- Va chạm từ HitArea2D ----------

func _on_hit_body_entered(body: Node) -> void:
	if _exploding:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	explode()

# ---------- Nổ ----------

func explode() -> void:
	if _exploding:
		return
	_exploding = true

	# AoE thêm nếu muốn
	if hit_area:
		for body in hit_area.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage)

	# TODO: chơi animation nổ nếu có
	queue_free()
