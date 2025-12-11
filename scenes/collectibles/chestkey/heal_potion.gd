extends InteractiveArea2D

@export var heal_amount: int = 1
var float_speed: float = 2.0
var float_height: float = 4.0
var base_y: float
var time_passed: float = 0.0

func _ready() -> void:
	$AnimatedSprite2D.play("appearance")
	interaction_available.connect(_on_interaction_available)
	super._ready()
		# lưu vị trí ban đầu để dao động
	base_y = $AnimatedSprite2D.position.y

func _process(delta: float) -> void:
	time_passed += delta * float_speed
	# dao động bằng sin
	$AnimatedSprite2D.position.y = base_y + sin(time_passed) * float_height

func collect_heal_potion() -> void:
	GameManager.inventory_system.add_heal_potion(heal_amount)
	$AnimatedSprite2D.scale = Vector2(1,1)
	$AnimatedSprite2D.play("disappearance")
	await $AnimatedSprite2D.animation_finished
	queue_free()

func _on_interaction_available() -> void:
	collect_heal_potion()
