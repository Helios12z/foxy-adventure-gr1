extends CanvasLayer
class_name VictoryScreen

## Victory screen with animated overlay and composite victory image

@onready var overlay: ColorRect = $Control/OverlayColorRect
@onready var victory_composite: Control = $Control/VictoryComposite
@onready var world_map_button: Button = $Control/WorldMapButton

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
	
	print("VictoryScreen ready! Overlay: ", overlay != null, ", Composite: ", victory_composite != null)
	
	# Initially hide elements
	if overlay:
		overlay.modulate.a = 0.0
	if victory_composite:
		victory_composite.modulate.a = 0.0
		victory_composite.scale = Vector2(0.8, 0.8)
	if world_map_button:
		world_map_button.modulate.a = 0.0
	
	# Animate in
	animate_in()
	
	# Connect button
	if world_map_button:
		world_map_button.pressed.connect(_on_world_map_button_pressed)

func animate_in() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade in overlay
	if overlay:
		tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	
	# Fade and scale in victory composite
	if victory_composite:
		tween.tween_property(victory_composite, "modulate:a", 1.0, 0.8).set_delay(0.3)
		tween.tween_property(victory_composite, "scale", Vector2.ONE, 0.8).set_delay(0.3).set_trans(Tween.TRANS_BACK)
	
	# Fade in button
	if world_map_button:
		tween.tween_property(world_map_button, "modulate:a", 1.0, 0.5).set_delay(0.8)

func _on_world_map_button_pressed() -> void:
	print("World Map button pressed!")
	# Unpause game
	get_tree().paused = false
	
	# Go to world map - this will automatically cleanup this screen
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)

func _exit_tree() -> void:
	# Make sure game is unpaused
	get_tree().paused = false
