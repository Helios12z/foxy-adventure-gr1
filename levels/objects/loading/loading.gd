extends Control

@onready var background: TextureRect = $Background
@onready var area_name: Label = $VBoxContainer/AreaName
@onready var tip_text: Label = $VBoxContainer/TipText
@onready var loading_bar: ProgressBar = $VBoxContainer/LoadingBar
@onready var continue_prompt: Label = $VBoxContainer/ContinuePrompt
@onready var loading_dots: Label = $VBoxContainer/LoadingDots

var loading_content: Dictionary
var current_tip: String
var loading_complete: bool = false

func _ready():
	continue_prompt.modulate.a = 0.0
	loading_bar.value = 0.0
	loading_dots.text = "Loading..."

func start_loading(target_scene_path: String):
	# Legacy method - fallback to destination-based loading
	start_loading_with_transition("", target_scene_path)

func start_loading_with_transition(from_scene: String, to_scene: String):
	# Load content based on transition
	if get_node_or_null("/root/LoadingManager"):
		loading_content = LoadingManager.get_content_for_transition(from_scene, to_scene)
	else:
		# Fallback content if LoadingManager is not available
		loading_content = {
			"tips": ["Loading..."],
			"area_name": "Unknown Lands",
			"loading_duration": 2.0
		}

	_setup_content()

	# Start fake loading progress
	_simulate_loading_progress()

func _setup_content():
	# Set area name
	area_name.text = loading_content.get("area_name", "Unknown Lands")

	# Set random tip
	var tips = loading_content.get("tips", [])
	if tips.size() > 0:
		var selected_tip = tips[randi() % tips.size()]
		tip_text.text = selected_tip

	# Set background image
	var images = loading_content.get("images", [])
	if images.size() > 0:
		var random_image = images[randi() % images.size()]
		background.texture = load(random_image)

func _simulate_loading_progress():
	var progress = 0.0
	var loading_duration = loading_content.get("loading_duration", 2.5)

	while progress < 100.0:
		progress += (100.0 / loading_duration) * get_process_delta_time()
		progress = min(progress, 100.0)

		# Update loading bar
		loading_bar.value = progress

		# Update loading dots animation
		var dot_count = int(Time.get_ticks_msec() / 500) % 4
		loading_dots.text = "Loading" + ".".repeat(dot_count)

		await get_tree().process_frame

	_on_loading_complete()

func _on_loading_complete():
	loading_complete = true
	loading_bar.value = 100.0
	loading_dots.text = "Loading Complete!"
	continue_prompt.modulate.a = 1.0

func _input(event):
	if loading_complete and event.is_pressed():
		# Continue to the game
		GameManager.finish_loading()
