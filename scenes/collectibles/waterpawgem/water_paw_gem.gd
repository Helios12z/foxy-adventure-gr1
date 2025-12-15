extends Node2D

@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 2.0

var _base_position: Vector2
var _t: float = 0.0
var _collected: bool = false

func _ready() -> void:
	_base_position = position
	if has_node("Area2D"):
		var area: Area2D = $Area2D
		area.body_entered.connect(_on_pickup_body_entered)

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_position.y + sin(_t * bob_speed) * bob_amplitude

func _on_pickup_body_entered(body: Node) -> void:
	if body is Player and not _collected:
		_collected = true

		# Disable collision to prevent multiple pickups
		if has_node("Area2D"):
			$Area2D.set_deferred("monitoring", false)

		# Collect the gem
		GameManager.collect_water_paw_gem()

		# Start the dialogue
		Dialogic.start("water_paw_gem_collected")
		Dialogic.timeline_ended.connect(_on_dialogue_finished)

func _on_dialogue_finished() -> void:
	Dialogic.timeline_ended.disconnect(_on_dialogue_finished)
	queue_free()
