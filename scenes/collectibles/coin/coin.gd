extends InteractiveArea2D

@export var coin_amount: int = 1
@export var coin_id: String = ""
@export var persistent: bool = true

var is_collected: bool = false
var is_flying: bool = false
var just_landed: bool = false

var t: float = 0.0
var speed: float = 1.0

var p0: Vector2
var p1: Vector2
var p2: Vector2
var p3: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_down: RayCast2D = $RayCast2D


func _ready() -> void:
	if coin_id.is_empty():
		coin_id = make_position_id()
	
	if persistent and GameManager.is_coin_collected(coin_id): 
		queue_free()
		return 
	
	sprite.play("appearance")
	interaction_available.connect(_on_interaction_available)
	super._ready()



func fly_to(target_pos: Vector2, arc_height: float = -90.0, fly_speed: float = 1.2) -> void:
	is_flying = true
	just_landed = false
	is_collected = false
	t = 0.0
	speed = fly_speed

	p0 = global_position
	p1 = p0 + Vector2(0, arc_height)
	p2 = target_pos + Vector2(0, arc_height)
	p3 = target_pos


func _process(delta: float) -> void:
	if is_flying:
		# ----------------------------------------------------
		# nếu raycast đụng ground → dừng bay (không cho nhặt ngay)
		# ----------------------------------------------------
		if ray_down.is_colliding():
			is_flying = false
			just_landed = true

			await get_tree().create_timer(0.15).timeout
			just_landed = false
			return

		# ----------------------------------------------------
		# Cập nhật Bezier
		# ----------------------------------------------------
		t += delta * speed
		if t >= 1.0:
			t = 1.0
			is_flying = false
			just_landed = true

			await get_tree().create_timer(0.15).timeout
			just_landed = false
			return

		var q0 = p0.lerp(p1, t)
		var q1 = p1.lerp(p2, t)
		var q2 = p2.lerp(p3, t)

		var r0 = q0.lerp(q1, t)
		var r1 = q1.lerp(q2, t)

		global_position = r0.lerp(r1, t)


# ----------------------------------------------------
# NHẶT COIN
# ----------------------------------------------------
func collect_coin() -> void:
	if is_flying or just_landed or is_collected:
		return

	is_collected = true   # <<-- CHỐT QUAN TRỌNG (chỉ nhặt 1 lần)

	GameManager.inventory_system.add_coin(coin_amount)
	if persistent and not coin_id.is_empty():
		GameManager.mark_coin_collected(coin_id)

	sprite.play("disappearance")
	await sprite.animation_finished
	queue_free()


func _on_interaction_available() -> void:
	collect_coin()
	
func make_position_id() -> String:
	var ix := int(round(global_position.x))
	var iy := int(round(global_position.y))
	return "%d:%d" % [ix, iy]
	
