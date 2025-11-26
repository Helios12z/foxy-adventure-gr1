extends InteractiveArea2D

func _ready() -> void:
	interaction_available.connect(_on_interaction_available)
	super._ready()

func collect_speed_up() -> void:
	GameManager.player.collect_powerup("speed_up")
	queue_free()

func _on_interaction_available() -> void:
	collect_speed_up()
