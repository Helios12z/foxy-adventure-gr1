extends Node2D

@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 2.5
var _phase: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
    _base_y = position.y
    var area := $Area2D
    if area and not area.is_connected("body_entered", Callable(self, "_on_pickup_body_entered")):
        area.body_entered.connect(_on_pickup_body_entered)

func _process(delta: float) -> void:
    _phase += delta * bob_speed
    position.y = _base_y + sin(_phase) * bob_amplitude

func _on_pickup_body_entered(body: Node) -> void:
    if body is Player:
        GameManager.collect_water_room_gem()
        queue_free()