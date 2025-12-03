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
var target_scene_path: String

func _ready():
	continue_prompt.modulate.a = 0.0
	loading_bar.value = 0.0
	loading_dots.text = "Loading..."

func start_loading(target_scene_path: String):
	# Legacy method - fallback to destination-based loading
	start_loading_with_transition("", target_scene_path)

func start_loading_with_transition(from_scene: String, to_scene: String):
	target_scene_path = to_scene
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

		# Safe await with null check
		var tree = get_tree()
		if tree:
			await tree.process_frame
		else:
			# Fallback: continue without waiting (will run faster but still works)
			pass

	_on_loading_complete()

func _on_loading_complete():
	loading_complete = true
	loading_bar.value = 100.0
	loading_dots.text = "Loading Complete!"
	continue_prompt.text = "Entering level..."
	continue_prompt.modulate.a = 1.0

	# Automatically transition to the target scene after a short delay
	await get_tree().create_timer(1.0).timeout
	_load_target_scene()

func _load_target_scene():
	if target_scene_path.is_empty():
		push_error("No target scene path set")
		return

	# Load the scene
	var packed = ResourceLoader.load(target_scene_path)
	if packed:
		print("Loading scene: ", target_scene_path)
		get_tree().change_scene_to_packed(packed)
	else:
		push_error("Could not load target scene: " + target_scene_path)
