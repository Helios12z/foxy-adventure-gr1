extends InteractiveArea2D

func _ready() -> void:
	interaction_available.connect(_on_interaction_available)
	super._ready()

func collect_blade() -> void:
	GameManager.player.collect_powerup("blade")
	queue_free()

func _on_interaction_available() -> void:
	collect_blade()
