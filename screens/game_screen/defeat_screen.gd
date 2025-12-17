extends CanvasLayer
class_name DefeatScreen

## Defeat screen with animated overlay, composite defeat image, and respawn/world map buttons

@onready var overlay: ColorRect = $Control/OverlayColorRect
@onready var defeat_composite: Control = $Control/DefeatComposite
@onready var world_map_button: Button = $Control/WorldMapButton
@onready var respawn_button: Button = $Control/RespawnButton

const WORLD_MAP_SCENE = "res://screens/game_screen/world_map_screen.tscn"

func _ready() -> void:
	# Set layer to be on top of everything
	layer = 100
	
	# Ensure this works even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Make sure Control fills the screen
	var control = $Control
	if control:
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Pause game
	get_tree().paused = true
	
	print("DefeatScreen ready! Overlay: ", overlay != null, ", Composite: ", defeat_composite != null)
	
	# Initially hide elements
	if overlay:
		overlay.modulate.a = 0.0
	if defeat_composite:
		defeat_composite.modulate.a = 0.0
		defeat_composite.scale = Vector2(0.8, 0.8)
	if world_map_button:
		world_map_button.modulate.a = 0.0
	if respawn_button:
		respawn_button.modulate.a = 0.0
	
	# Animate in
	animate_in()
	
	# Connect buttons
	if world_map_button:
		world_map_button.pressed.connect(_on_world_map_button_pressed)
	if respawn_button:
		respawn_button.pressed.connect(_on_respawn_button_pressed)

func animate_in() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade in overlay
	if overlay:
		tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	
	# Fade and scale in defeat composite
	if defeat_composite:
		tween.tween_property(defeat_composite, "modulate:a", 1.0, 0.8).set_delay(0.3)
		tween.tween_property(defeat_composite, "scale", Vector2.ONE, 0.8).set_delay(0.3).set_trans(Tween.TRANS_BACK)
	
	# Fade in buttons
	if world_map_button:
		tween.tween_property(world_map_button, "modulate:a", 1.0, 0.5).set_delay(0.8)
	if respawn_button:
		tween.tween_property(respawn_button, "modulate:a", 1.0, 0.5).set_delay(0.8)

func _on_world_map_button_pressed() -> void:
	print("World Map button pressed from Defeat Screen!")
	# Unpause game
	get_tree().paused = false
	
	# Go to world map - this will automatically cleanup this screen
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)

func _on_respawn_button_pressed() -> void:
	print("Respawn button pressed!")
	# Unpause game
	get_tree().paused = false
	
	# Respawn at checkpoint
	if GameManager.has_checkpoint():
		GameManager.respawn_at_checkpoint()
	
	# Remove this screen after respawn
	queue_free()

func _exit_tree() -> void:
	# Make sure game is unpaused
	get_tree().paused = false
