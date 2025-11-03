extends StaticBody2D

func _ready() -> void:
	if has_node("PickupArea"):
		var area: Area2D = $PickupArea
		area.body_entered.connect(_on_pickup_body_entered)

func _on_pickup_body_entered(body: Node) -> void:
	if body is Player:
		GameManager.collect_blade()
		queue_free()
