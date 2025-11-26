class_name MagnetDecorator
extends PowerupDecorator

var magnet_strength: float = 100.0
var magnet_area: Area2D = null

func on_apply():
	super.on_apply()

	# MagnetArea2D nằm TRỰC TIẾP trong Direction
	magnet_area = player.get_node_or_null("Direction/MagnetArea2D")

	if magnet_area == null:
		push_error("❌ MagnetArea2D not found at Direction/MagnetArea2D")
		return

	magnet_area.monitoring = true
	magnet_area.monitorable = true

	# Layer và mask
	magnet_area.set_collision_layer_value(6, true)
	magnet_area.set_collision_mask_value(7, true)

	print("Magnet activated! Found:", magnet_area)


func update(delta: float) -> bool:
	if magnet_area:
		_pull_items(delta)
	return super.update(delta)


func _pull_items(delta: float):
	if magnet_area == null:
		return

	for area in magnet_area.get_overlapping_areas():
		if area.is_in_group("collectible"):
			_attract_item(area, delta)

	for body in magnet_area.get_overlapping_bodies():
		if body.is_in_group("collectible"):
			_attract_item(body, delta)


func _attract_item(item: Node2D, delta: float):
	item.global_position = item.global_position.move_toward(player.global_position,magnet_strength * delta)
	


func on_remove():
	super.on_remove()

	if magnet_area:
		magnet_area.monitoring = false
		magnet_area.monitorable = false

	print("Magnet removed.")
