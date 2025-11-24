extends Node2D

@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 2.0

var _base_position: Vector2
var _t: float = 0.0

func _ready() -> void:
	_base_position = position
	if has_node("Area2D"):
		var area: Area2D = $Area2D
		area.body_entered.connect(_on_pickup_body_entered)

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_position.y + sin(_t * bob_speed) * bob_amplitude

func _on_pickup_body_entered(body: Node) -> void:
	if body is Player:
		GameManager.collect_fire_gem()
		var popup_scene = load("res://levels/tutorial/signpost_details/susanoo_tutorial_popup.tscn")
		if popup_scene:
			var popup = popup_scene.instantiate()
			var root = get_tree().current_scene
			if root:
				var ui_layer = root.find_child("UILayer", true, false)
				if ui_layer == null:
					ui_layer = CanvasLayer.new()
					ui_layer.name = "UILayer"
					root.add_child(ui_layer)
				ui_layer.add_child(popup)
				if popup.has_method("show_popup"):
					popup.show_popup()
		queue_free()
