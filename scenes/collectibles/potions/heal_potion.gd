extends InteractiveArea2D

@export var heal_amount: int = 1

func _ready() -> void:
	$AnimatedSprite2D.play("appearance")
	interaction_available.connect(_on_interaction_available)
	super._ready()

func collect_heal_potion() -> void:
	GameManager.inventory_system.add_heal_potion(heal_amount)
	$AnimatedSprite2D.scale = Vector2(1, 1)
	$AnimatedSprite2D.play("disappearance")
	await $AnimatedSprite2D.animation_finished
	queue_free()

func _on_interaction_available() -> void:
	collect_heal_potion()
