extends CanvasLayer
class_name VictoryScreen

## Victory screen with animated overlay, composite victory image, and fireworks

@onready var overlay: ColorRect = $Control/OverlayColorRect
@onready var victory_composite: Control = $Control/VictoryComposite
@onready var world_map_button: Button = $Control/WorldMapButton

# Composite Elements
@onready var background: TextureRect = $Control/VictoryComposite/Background
@onready var wheel: TextureRect = $Control/VictoryComposite/Wheel1
@onready var foxy: TextureRect = $Control/VictoryComposite/FoxyVictory
@onready var banner: TextureRect = $Control/VictoryComposite/Banner
@onready var rainbow: TextureRect = $Control/VictoryComposite/Rainbow
@onready var gun1: TextureRect = $Control/VictoryComposite/Gun1
@onready var gun2: TextureRect = $Control/VictoryComposite/Gun2

# Stars Group
@onready var stars_group: Node2D = $Control/VictoryComposite/Stars
@onready var star1: TextureRect = $Control/VictoryComposite/Stars/Star1
@onready var star2: TextureRect = $Control/VictoryComposite/Stars/Star2
@onready var star3: TextureRect = $Control/VictoryComposite/Stars/Star3
@onready var star4: TextureRect = $Control/VictoryComposite/Stars/Star4

# Fireworks
@onready var fireworks1: CPUParticles2D = $Control/Fireworks1
@onready var fireworks2: CPUParticles2D = $Control/Fireworks2

const WORLD_MAP_SCENE = "res://screens/game_screen/world_map_screen.tscn"

# Store original positions
var orig_pos_wheel: Vector2
var orig_pos_rainbow: Vector2
var orig_pos_banner: Vector2
var orig_pos_foxy: Vector2
var orig_pos_gun1: Vector2
var orig_pos_gun2: Vector2
var orig_pos_stars: Vector2
var orig_pos_btn: Vector2

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
	
	print("VictoryScreen ready!")
	
	# Setup Initial State (Hidden & Offset DOwn)
	var offset_y = 60.0
	var offset_node = func(node):
		if node:
			node.modulate.a = 0.0
			node.position.y += offset_y
			return node.position - Vector2(0, offset_y)
		return Vector2.ZERO
	
	if overlay: overlay.modulate.a = 0.0
	
	# Initialize positions
	if wheel: orig_pos_wheel = offset_node.call(wheel)
	if rainbow: orig_pos_rainbow = offset_node.call(rainbow)
	if banner: orig_pos_banner = offset_node.call(banner)
	if foxy: orig_pos_foxy = offset_node.call(foxy)
	if gun1: orig_pos_gun1 = offset_node.call(gun1)
	if gun2: orig_pos_gun2 = offset_node.call(gun2)
	
	if world_map_button: 
		orig_pos_btn = offset_node.call(world_map_button)
	
	# Handle stars individually for alpha, group for position
	if star1: star1.modulate.a = 0.0
	if star2: star2.modulate.a = 0.0
	if star3: star3.modulate.a = 0.0
	if star4: star4.modulate.a = 0.0
	
	if stars_group:
		orig_pos_stars = stars_group.position
		stars_group.position.y += offset_y
	
	# 1. Animate In
	animate_in()
	
	# 2. Apply Bouncy Shader
	
	# Background Elements - Pulse then stop. Loop=false, Pivot=0.5 (Center)
	apply_bounce_shader(background, 3.0, 5.0, 2.0, false)
	apply_bounce_shader(wheel, 4.0, 8.0, 2.0, false)
	apply_bounce_shader(rainbow, 2.0, 5.0, 3.0, false)
	
	# Main Elements - bouncy
	apply_bounce_shader(banner, 4.0, 10.0, 1.5, false)
	apply_bounce_shader(gun1, 5.0, 12.0, 1.5, false)
	apply_bounce_shader(gun2, 5.0, 12.0, 1.5, false)
	
	# Stars
	apply_bounce_shader(star1, 4.0, 8.0, 1.5, false)
	apply_bounce_shader(star2, 4.0, 8.0, 1.5, false)
	apply_bounce_shader(star3, 4.0, 8.0, 1.5, false)
	apply_bounce_shader(star4, 4.0, 8.0, 1.5, false)
	
	# Button matches style
	apply_bounce_shader(world_map_button, 5.0, 10.0, 1.5, false)
	
	# FOXY: Infinite Loop, Pivot at Bottom, with Sway (rotation wiggle)
	# Very gentle: Amp 1.5, Sway 0.1 radian (~5.7 degrees)
	apply_bounce_shader(foxy, 4.0, 1.5, 0.0, true, 1.0, 0.1) 
	
	# 3. Start Fireworks Loop
	start_fireworks()
	
	# Connect button
	if world_map_button:
		world_map_button.pressed.connect(_on_world_map_button_pressed)

func apply_bounce_shader(node: CanvasItem, speed: float, start_amp: float, duration: float, loop: bool, pivot_y: float = 0.5, sway: float = 0.0) -> void:
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
		mat.set_shader_parameter("pivot_y", pivot_y)
		mat.set_shader_parameter("sway_amount", sway)
		
		# If foxy (looping), use very gentle squash
		var squash = 0.8 
		if loop: squash = 0.15 # Even softer for foxy (was 0.2)
		
		mat.set_shader_parameter("squash_amount", squash) 
		node.material = mat
		
		# If NOT looping, tween to stop
		if not loop:
			var tween = create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(mat, "shader_parameter/bounce_amplitude", 0.0, duration).set_delay(0.2)
			tween.parallel().tween_property(mat, "shader_parameter/squash_amount", 0.0, duration).set_delay(0.2)
			
func animate_in() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK) # Overshoot style
	
	# Overlay
	if overlay:
		var t_ov = create_tween()
		t_ov.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t_ov.tween_property(overlay, "modulate:a", 1.0, 0.5)
	
	var dur = 0.6
	
	# Staggered appearances
	var t1 = 0.2 # Wheel/Rainbow/BG
	var t2 = 0.3 # Banner/Stars
	var t3 = 0.5 # Foxy
	var t4 = 0.7 # Guns
	var t5 = 0.9 # Button
	
	if wheel:
		tween.tween_property(wheel, "position", orig_pos_wheel, dur).set_delay(t1)
		tween.tween_property(wheel, "modulate:a", 1.0, 0.4).set_delay(t1).set_trans(Tween.TRANS_LINEAR)
	if rainbow:
		tween.tween_property(rainbow, "position", orig_pos_rainbow, dur).set_delay(t1)
		tween.tween_property(rainbow, "modulate:a", 1.0, 0.4).set_delay(t1).set_trans(Tween.TRANS_LINEAR)
		
	if banner:
		tween.tween_property(banner, "position", orig_pos_banner, dur).set_delay(t2)
		tween.tween_property(banner, "modulate:a", 1.0, 0.4).set_delay(t2).set_trans(Tween.TRANS_LINEAR)
		
	if stars_group:
		tween.tween_property(stars_group, "position", orig_pos_stars, dur).set_delay(t2)
		var t_star_fade = Tween.TRANS_LINEAR
		if star1: tween.parallel().tween_property(star1, "modulate:a", 1.0, 0.4).set_delay(t2).set_trans(t_star_fade)
		if star2: tween.parallel().tween_property(star2, "modulate:a", 1.0, 0.4).set_delay(t2).set_trans(t_star_fade)
		if star3: tween.parallel().tween_property(star3, "modulate:a", 1.0, 0.4).set_delay(t2).set_trans(t_star_fade)
		if star4: tween.parallel().tween_property(star4, "modulate:a", 1.0, 0.4).set_delay(t2).set_trans(t_star_fade)

	if foxy:
		tween.tween_property(foxy, "position", orig_pos_foxy, dur).set_delay(t3)
		tween.tween_property(foxy, "modulate:a", 1.0, 0.4).set_delay(t3).set_trans(Tween.TRANS_LINEAR)

	if gun1:
		tween.tween_property(gun1, "position", orig_pos_gun1, dur).set_delay(t4)
		tween.tween_property(gun1, "modulate:a", 1.0, 0.4).set_delay(t4).set_trans(Tween.TRANS_LINEAR)
	if gun2:
		tween.tween_property(gun2, "position", orig_pos_gun2, dur).set_delay(t4)
		tween.tween_property(gun2, "modulate:a", 1.0, 0.4).set_delay(t4).set_trans(Tween.TRANS_LINEAR)
		
	if world_map_button:
		tween.tween_property(world_map_button, "position", orig_pos_btn, dur).set_delay(t5)
		tween.tween_property(world_map_button, "modulate:a", 1.0, 0.4).set_delay(t5).set_trans(Tween.TRANS_LINEAR)

func start_fireworks() -> void:
	# Continuous Loop
	while is_inside_tree():
		spawn_firework_pair()
		# Wait 1.2s, Must process ALWAYS (ignoring pause)
		if get_tree():
			await get_tree().create_timer(1.2, true, false, true).timeout

func spawn_firework_pair() -> void:
	if not fireworks1 or not fireworks2: return
	
	var screen_str = get_viewport().get_visible_rect().size
	# Pick 2 random points
	var p1 = Vector2(randf() * screen_str.x, randf() * screen_str.y * 0.8)
	var p2 = Vector2(randf() * screen_str.x, randf() * screen_str.y * 0.8)
	
	# MULTICOLOR CONFETTI SETUP
	# Create a rainbow gradient
	var gradient = Gradient.new()
	gradient.set_color(0, Color.RED)           # 0.0
	gradient.add_point(0.16, Color.ORANGE)     
	gradient.add_point(0.33, Color.YELLOW)     
	gradient.add_point(0.5, Color.GREEN)       
	gradient.add_point(0.66, Color.CYAN)       
	gradient.add_point(0.83, Color.BLUE)       
	gradient.set_color(1, Color.MAGENTA)       # 1.0
	
	# KEY FIX: Use color_initial_ramp (each particle picks ONE random color at spawn)
	# NOT color_ramp (which animates color over lifetime)
	fireworks1.color_initial_ramp = gradient
	fireworks2.color_initial_ramp = gradient
	
	# Clear color_ramp (no color animation over time)
	fireworks1.color_ramp = null
	fireworks2.color_ramp = null
	
	# Set base color to WHITE
	fireworks1.color = Color.WHITE
	fireworks2.color = Color.WHITE
	
	# Clear hue variation
	fireworks1.hue_variation_min = 0.0
	fireworks1.hue_variation_max = 0.0
	fireworks2.hue_variation_min = 0.0
	fireworks2.hue_variation_max = 0.0

	fireworks1.global_position = p1
	fireworks1.restart()
	fireworks1.emitting = true
	
	fireworks2.global_position = p2
	fireworks2.restart()
	fireworks2.emitting = true

func _on_world_map_button_pressed() -> void:
	print("World Map button pressed!")
	# Unpause game
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)

func _exit_tree() -> void:
	# Make sure game is unpaused
	get_tree().paused = false
