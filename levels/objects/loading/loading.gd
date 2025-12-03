extends Control

@onready var loading_label: Label = $Label

var loading_content: Dictionary
var current_tip: String
var loading_complete: bool = false

func _ready():
	loading_label.text = "Loading..."

func start_loading(target_scene_path: String):
	# Load content for the target area
	if get_node_or_null("/root/LoadingManager"):
		loading_content = LoadingManager.get_content_for_scene(target_scene_path)
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
	# Set area name and tip in the loading label
	var area_name = loading_content.get("area_name", "Unknown Lands")
	var tips = loading_content.get("tips", [])

	var tip_text = ""
	if tips.size() > 0:
		tip_text = tips[randi() % tips.size()]

	loading_label.text = "Entering: " + area_name + "\n\n" + tip_text + "\n\nLoading..."

func _simulate_loading_progress():
	var progress = 0.0
	var loading_duration = loading_content.get("loading_duration", 2.5)
	var dots = ""

	while progress < 100.0:
		progress += (100.0 / loading_duration) * get_process_delta_time()
		progress = min(progress, 100.0)

		# Update loading dots
		dots = ".".repeat(int(progress / 25) + 1)
		var base_text = loading_label.text.rstrip(".") + dots
		loading_label.text = base_text

		await get_tree().process_frame

	_on_loading_complete()

func _on_loading_complete():
	loading_complete = true
	loading_label.text = loading_label.text.replace("Loading", "Press any key to continue")
	loading_label.text += "\n\nReady!"

func _input(event):
	if loading_complete and event.is_pressed():
		# Continue to the game
		GameManager.finish_loading()
