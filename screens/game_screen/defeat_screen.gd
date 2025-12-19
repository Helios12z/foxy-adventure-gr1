extends CanvasLayer
class_name DefeatScreen

## Defeat screen with bouncy entrance animation

@onready var overlay: ColorRect = $Control/OverlayColorRect
@onready var defeat_composite: Control = $Control/DefeatComposite

# Composite Elements
@onready var background: TextureRect = $Control/DefeatComposite/Background
@onready var wheel: TextureRect = $Control/DefeatComposite/WheelLose
# Use get_node_or_null where names might vary or to be safe
@onready var foxy: AnimatedSprite2D = $Control/DefeatComposite/FoxyCry

# Individual Stars (Node2D parent doesn't handle shader well)
@onready var stars_group: Node2D = $Control/DefeatComposite/DarkStars
@onready var star1: TextureRect = $Control/DefeatComposite/DarkStars/Star1
@onready var star2: TextureRect = $Control/DefeatComposite/DarkStars/Star2
@onready var star3: TextureRect = $Control/DefeatComposite/DarkStars/Star3

@onready var gun1: TextureRect = $Control/DefeatComposite/Gun
@onready var gun2: TextureRect = $Control/DefeatComposite/Gun2
@onready var banner: Sprite2D = $Control/DefeatComposite/BannerL

@onready var world_map_button: Button = $Control/WorldMapButton
@onready var respawn_button: Button = $Control/RespawnButton

const WORLD_MAP_SCENE = "res://screens/game_screen/world_map_screen.tscn"

# Store original positions for animation
var orig_pos_wheel: Vector2
var orig_pos_foxy: Vector2
var orig_pos_stars: Vector2
var orig_pos_gun1: Vector2
var orig_pos_gun2: Vector2
var orig_pos_banner: Vector2
var orig_pos_btn_map: Vector2
var orig_pos_btn_respawn: Vector2

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var control = $Control
	if control:
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	get_tree().paused = true
	
	# 1. SETUP INITIAL STATE (Hidden & Offset)
	# We move elements DOWN slightly so they can bounce UP into place
	var offset_y = 50.0
	var offset_node = func(node):
		if node:
			node.modulate.a = 0.0
			node.position.y += offset_y
			return node.position - Vector2(0, offset_y) # Return orig pos
		return Vector2.ZERO

	if overlay: overlay.modulate.a = 0.0
	
	if wheel: orig_pos_wheel = offset_node.call(wheel)
	if foxy: orig_pos_foxy = offset_node.call(foxy)
	if gun1: orig_pos_gun1 = offset_node.call(gun1)
	if gun2: orig_pos_gun2 = offset_node.call(gun2)
	if banner: orig_pos_banner = offset_node.call(banner)
	if world_map_button: orig_pos_btn_map = offset_node.call(world_map_button)
	if respawn_button: orig_pos_btn_respawn = offset_node.call(respawn_button)
	
	# Handle stars group manually
	if star1: star1.modulate.a = 0.0
	if star2: star2.modulate.a = 0.0
	if star3: star3.modulate.a = 0.0
	# Move parent
	if stars_group:
		orig_pos_stars = stars_group.position
		stars_group.position.y += offset_y

	
	# Start Animation
	animate_in()
	
	# Apply Bouncy Shader (Bounce then stop)
	# Args: Node, Speed, Start Amplitude, Duration to stop
	apply_bounce_shader(foxy, 3.0, 10.0, 1.5)
	apply_bounce_shader(gun1, 2.5, 5.0, 1.2)
	apply_bounce_shader(gun2, 2.5, 5.0, 1.2)
	apply_bounce_shader(banner, 2.0, 3.0, 1.0)
	
	# New elements added (Stronger deformation for everyone)
	apply_bounce_shader(background, 1.0, 5.0, 2.0) # Clouds/BG
	
	# Apply to individual stars
	apply_bounce_shader(star1, 2.0, 5.0, 1.5)
	apply_bounce_shader(star2, 2.0, 5.0, 1.5)
	apply_bounce_shader(star3, 2.0, 5.0, 1.5)
	
	apply_bounce_shader(wheel, 2.0, 4.0, 1.5)
	
	apply_bounce_shader(world_map_button, 3.0, 4.0, 1.2)
	apply_bounce_shader(respawn_button, 3.0, 4.0, 1.2)
	
	# Connect buttons
	if world_map_button:
		world_map_button.pressed.connect(_on_world_map_button_pressed)
	if respawn_button:
		respawn_button.pressed.connect(_on_respawn_button_pressed)

func apply_bounce_shader(node: CanvasItem, speed: float, start_amp: float, duration: float) -> void:
	if not node: return
	
	var rect_size = Vector2.ZERO
	if node is Control:
		rect_size = node.size
	elif node is Sprite2D and node.texture:
		rect_size = node.texture.get_size()
	
	var shader = load("res://shaders/bouncy_deform.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("rect_size", rect_size)
		mat.set_shader_parameter("bounce_speed", speed)
		mat.set_shader_parameter("bounce_amplitude", start_amp)
		mat.set_shader_parameter("squash_amount", 0.6) # VERY Strong Squash (60%)
		node.material = mat
		
		# Tween the amplitude down to 0 to stop the bouncing
		# IMPORTANT: Must set TWEEN_PAUSE_PROCESS because the game is paused!
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		# Bounce then stop (Amplitude -> 0, Squash -> 0)
		tween.tween_property(mat, "shader_parameter/bounce_amplitude", 0.0, duration).set_delay(0.2)
		tween.parallel().tween_property(mat, "shader_parameter/squash_amount", 0.0, duration).set_delay(0.2)

func animate_in() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	# Use TRANS_BACK for that "Bouncy/Nhún" effect (overshoots and settles)
	# Use EASE_OUT for natural deceleration
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# 0. Background Overlay (Simple fade)
	if overlay:
		var t_overlay = create_tween() # Separate linear tween for overlay
		t_overlay.tween_property(overlay, "modulate:a", 1.0, 0.5)
	
	# SEQUENCE TIMING
	var t_wheel = 0.2
	var t_stars = 0.3
	var t_guns = 0.4
	var t_banner = 0.5
	var t_foxy = 0.7  # Fox appears later
	var t_btns = 0.9  # Buttons appear last
	
	var dur = 0.6 # Duration of bounce
	
	# Element Animations: Move Y back to original AND Fade In
	if wheel:
		tween.tween_property(wheel, "position", orig_pos_wheel, dur).set_delay(t_wheel)
		tween.tween_property(wheel, "modulate:a", 1.0, 0.4).set_delay(t_wheel).set_trans(Tween.TRANS_LINEAR)
		
	if stars_group:
		tween.tween_property(stars_group, "position", orig_pos_stars, dur).set_delay(t_stars)
		if star1: tween.parallel().tween_property(star1, "modulate:a", 1.0, 0.4).set_delay(t_stars).set_trans(Tween.TRANS_LINEAR)
		if star2: tween.parallel().tween_property(star2, "modulate:a", 1.0, 0.4).set_delay(t_stars).set_trans(Tween.TRANS_LINEAR)
		if star3: tween.parallel().tween_property(star3, "modulate:a", 1.0, 0.4).set_delay(t_stars).set_trans(Tween.TRANS_LINEAR)

	if gun1:
		tween.tween_property(gun1, "position", orig_pos_gun1, dur).set_delay(t_guns)
		tween.tween_property(gun1, "modulate:a", 1.0, 0.4).set_delay(t_guns).set_trans(Tween.TRANS_LINEAR)

	if gun2:
		tween.tween_property(gun2, "position", orig_pos_gun2, dur).set_delay(t_guns)
		tween.tween_property(gun2, "modulate:a", 1.0, 0.4).set_delay(t_guns).set_trans(Tween.TRANS_LINEAR)

	if banner:
		tween.tween_property(banner, "position", orig_pos_banner, dur).set_delay(t_banner)
		tween.tween_property(banner, "modulate:a", 1.0, 0.4).set_delay(t_banner).set_trans(Tween.TRANS_LINEAR)

	if foxy:
		tween.tween_property(foxy, "position", orig_pos_foxy, dur).set_delay(t_foxy)
		tween.tween_property(foxy, "modulate:a", 1.0, 0.4).set_delay(t_foxy).set_trans(Tween.TRANS_LINEAR)

	if world_map_button:
		tween.tween_property(world_map_button, "position", orig_pos_btn_map, dur).set_delay(t_btns)
		tween.tween_property(world_map_button, "modulate:a", 1.0, 0.4).set_delay(t_btns).set_trans(Tween.TRANS_LINEAR)
		
	if respawn_button:
		tween.tween_property(respawn_button, "position", orig_pos_btn_respawn, dur).set_delay(t_btns)
		tween.tween_property(respawn_button, "modulate:a", 1.0, 0.4).set_delay(t_btns).set_trans(Tween.TRANS_LINEAR)

func _on_world_map_button_pressed() -> void:
	# Unpause game
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)

func _on_respawn_button_pressed() -> void:
	# Unpause game
	get_tree().paused = false
	
	# Safety cleanup
	GameManager.target_portal_name = ""
	
	if GameManager.has_checkpoint():
		var checkpoint_info = GameManager.load_checkpoint(GameManager.current_checkpoint_id)
		var stage_path = checkpoint_info.get("stage_path", "")
		
		# If checkpoint is in a different map -> Change stage
		if stage_path != "" and stage_path != get_tree().current_scene.scene_file_path:
			GameManager.change_stage(stage_path)
		else:
			# Same map -> Reload scene to reset all state (enemies, items, etc.)
			# Stage._ready() or similar logic will handle jumping to checkpoint upon reload
			get_tree().reload_current_scene()
	else:
		# Fallback: Just reload
		get_tree().reload_current_scene()
		
	queue_free()

func _exit_tree() -> void:
	get_tree().paused = false
