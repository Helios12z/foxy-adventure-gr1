extends PlayerState

# Water Paw state: spawn a water paw effect and toggle PawHitArea
# Brief effect; return to idle immediately after spawning.

var paw_scene: PackedScene = null

func _enter() -> void:
	# Require gem
	if not obj.has_water_paw_gem:
		change_state(fsm.states.idle)
		return
	# Kiểm tra mana (cần 50 mana = nửa cây)
	if not obj.can_use_skill(50):
		change_state(fsm.states.idle)
		return
	# Tiêu tốn 50 mana
	obj.take_mana(50)
	# Load scene lazily
	if paw_scene == null:
		paw_scene = load("res://scenes/skills/room_paw/water_paw.tscn") as PackedScene
	var effect := paw_scene.instantiate()
	effect.name = "WaterPawEffect"
	# Place at player and flip to facing
	if effect is Node2D:
		(effect as Node2D).global_position = obj.global_position
		(effect as Node2D).scale.x = float(obj.direction)
	# Attach to player
	obj.add_child(effect)
	# Let the effect manage lifetime and detection via its script
	# Return control back to idle
	change_state(fsm.states.idle)

func _update(_delta: float) -> void:
	pass

func _exit() -> void:
	pass