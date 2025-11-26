extends InteractiveArea2D

@export var key_amount: int = 1

func _ready() -> void:
	$AnimatedSprite2D.play("appearance")
	interaction_available.connect(_on_interaction_available)
	super._ready()

func collect_key() -> void:
	GameManager.inventory_system.add_key(key_amount)
	$AnimatedSprite2D.play("disappearance")
	await $AnimatedSprite2D.animation_finished
	queue_free()

func _on_interaction_available() -> void:
	collect_key()
