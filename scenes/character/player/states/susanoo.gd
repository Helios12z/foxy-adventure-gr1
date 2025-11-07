extends PlayerState

# Susanoo state: toggles the Susanoo spirit. On enter, spawn it behind
# the player with the appearance sequence, then return to idle.

var susanoo_scene: PackedScene = null

func _enter() -> void:
	# Load scene lazily
	if susanoo_scene == null:
		susanoo_scene = load("res://scenes/skills/susanoo/susanoo.tscn") as PackedScene
	# Nếu không có fire gem, thoát về idle
	if not obj.has_fire_gem:
		change_state(fsm.states.idle)
		return
	# Nếu đã có spirit, không làm gì cả
	var existing := obj.get_node_or_null("SusanooSpirit")
	if existing != null:
		change_state(fsm.states.idle)
		return

	# Spawn Susanoo behind player
	var spirit := susanoo_scene.instantiate()
	spirit.name = "SusanooSpirit"
	obj.add_child(spirit)
	# Make spirit independent of Player transform so follow smoothing applies to movement
	if spirit.has_method("set_as_top_level"):
		spirit.set_as_top_level(true)
	# Position behind player immediately; script will follow smoothly afterwards
	var dir := obj.direction
	spirit.global_position = obj.global_position + Vector2(-60 * dir, -8)

	# Appearance đã bỏ, spirit hiển thị ngay lập tức

	# Return control to idle after toggling
	change_state(fsm.states.idle)

func _update(_delta: float) -> void:
	pass

func _exit() -> void:
	pass
