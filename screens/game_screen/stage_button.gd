extends Control
class_name StageButton

## Stage button - Supports Manual Polygon Hit-Zone for perfect detection

@export var stage_id: int = 1  # 1-9
@export_file("*.tscn") var target_scene: String = ""
@export var target_door: String = "Door"
@export var pivot_adjustment: Vector2 = Vector2.ZERO # Manual fix for off-center sprites

@onready var texture_button: TextureButton = $TextureButton
@onready var icon: TextureRect = $TextureButton/Icon
@onready var popup_label: PopUpLabel = $PopUpLabel

var is_unlocked: bool = false
var is_next_stage: bool = false
var hover_scale: float = 1.15
var normal_scale: Vector2 = Vector2.ONE
var glow_material: ShaderMaterial = null

# State tracking for manual input handling
var is_hovering: bool = false
var hit_zone: Polygon2D = null # The manual polygon drawn by user

func _ready() -> void:
	if popup_label:
		popup_label.visible = false
	
	if icon:
		# 1. HIT ZONE DETECT (Find Polygon FIRST)
		for child in icon.get_children():
			if child is Polygon2D:
				hit_zone = child
				hit_zone.visible = false # Hide visual polygon in game
				print("Stage ", stage_id, ": Found manual Hit-Zone Polygon.")
				break
		
		# 2. CALCULATE AUTOMATIC PIVOT
		var new_pivot = Vector2.ZERO
		
		if hit_zone and hit_zone.polygon.size() > 0:
			# Calculate Centroid of Polygon (Average of all points)
			var sum_points = Vector2.ZERO
			for pt in hit_zone.polygon:
				sum_points += pt
			var centroid = sum_points / hit_zone.polygon.size()
			
			# Use Centroid + Optional Manual Adjustment
			new_pivot = centroid + pivot_adjustment
			print("Stage ", stage_id, ": Auto-Pivot set to ", new_pivot)
		else:
			# Fallback to Geometric Center
			new_pivot = (icon.size / 2) + pivot_adjustment
			
		# 3. APPLY PIVOT & COMPENSATE POSITION
		# This keeps the image roughly in the same visual place despite pivot change
		icon.pivot_offset = new_pivot
		icon.position += new_pivot * (icon.scale - Vector2.ONE)
		
		normal_scale = icon.scale
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Disable parent interaction
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if texture_button:
		texture_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	setup_glow_shader()
	update_stage_status()
	update_visuals()

# --------------------------------------------------------------------------
# POLYGON-AWARE INPUT HANDLING
# --------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not is_unlocked or not icon or not icon.is_visible_in_tree():
		return
	
	if event is InputEventMouse:
		var has_point = false
		
		if hit_zone and hit_zone.polygon.size() > 0:
			# STRATEGY A: Precise Polygon Check
			# Transform global mouse to local Icon space (matches Polygon space)
			var local_mouse = icon.get_global_transform().affine_inverse() * event.global_position
			if Geometry2D.is_point_in_polygon(local_mouse, hit_zone.polygon):
				has_point = true
		else:
			# STRATEGY B: Fallback to Rect Check (if no polygon drawn yet)
			if icon.get_global_rect().has_point(event.global_position):
				has_point = true
		
		# Logic handling
		if has_point:
			if not is_hovering:
				is_hovering = true
				_manual_mouse_entered()
			
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				_manual_pressed()
		else:
			if is_hovering:
				is_hovering = false
				_manual_mouse_exited()

# --------------------------------------------------------------------------

func setup_glow_shader() -> void:
	var shader = load("res://shaders/golden_glow.gdshader")
	if shader:
		glow_material = ShaderMaterial.new()
		glow_material.shader = shader

func update_stage_status() -> void:
	var completed_stages = GameManager.checkpoint_data.get("completed_stages", [])
	
	# Default State
	is_unlocked = false
	is_next_stage = false
	
	# FORCE INT to avoid float mismatch
	var current_id = int(stage_id)
	
	# Check if THIS stage is already completed
	var is_completed = completed_stages.has(current_id)
	
	if is_completed:
		# If completed, it's unlocked but NOT the next stage
		is_unlocked = true
		is_next_stage = false
	else:
		# If NOT completed, check if it SHOULD be the next stage
		if current_id == 1:
			# Stage 1 is always unlocked and is next if not completed
			is_unlocked = true
			is_next_stage = true
		else:
			# Other stages are Next if the previous one is completed
			var prev_stage_completed = completed_stages.has(current_id - 1)
			if prev_stage_completed:
				is_unlocked = true
				is_next_stage = true
			else:
				# Locked
				is_unlocked = false
				is_next_stage = false

func update_visuals() -> void:
	if not icon: return
	icon.material = null
	icon.modulate = Color.WHITE 
	
	if is_next_stage and glow_material:
		icon.material = glow_material
		# NEXT STAGE: Soft Pulsing Aura (Double Width)
		glow_material.set_shader_parameter("glow_intensity", 2.0) 
		glow_material.set_shader_parameter("is_pulsing", true)
		glow_material.set_shader_parameter("pulse_speed", 3.0)
		glow_material.set_shader_parameter("outline_width", 50.0) 

func _manual_mouse_entered() -> void:
	# Hover Effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(icon, "scale", normal_scale * hover_scale, 0.2)
	
	# Glow on hover
	if glow_material:
		icon.material = glow_material
		# HOVER: Big Soft Holy Aura (No Pulse)
		# Intensity 2.5 keeps it soft. 5.0 makes it too hard/solid.
		glow_material.set_shader_parameter("glow_intensity", 2.5) 
		glow_material.set_shader_parameter("is_pulsing", false)
		glow_material.set_shader_parameter("outline_width", 50.0) 

	if popup_label:
		popup_label.visible = true

func _manual_mouse_exited() -> void:
	# Reset Effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "scale", normal_scale, 0.15)
	
	if is_next_stage and glow_material:
		# Return to Next Stage state
		glow_material.set_shader_parameter("glow_intensity", 2.0)
		glow_material.set_shader_parameter("is_pulsing", true)
		glow_material.set_shader_parameter("outline_width", 50.0)
	else:
		icon.material = null

	if popup_label:
		popup_label.visible = false

func _manual_pressed() -> void:
	print("✅ Stage Clicked (Polygon): ", stage_id)
	if target_scene and not target_scene.is_empty():
		GameManager.target_portal_name = target_door
		GameManager.change_stage_with_loading(target_scene)
	else:
		push_error("Target scene missing for Stage " + str(stage_id))
