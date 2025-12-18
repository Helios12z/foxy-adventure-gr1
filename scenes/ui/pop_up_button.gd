@tool
extends Button
class_name PopUpButton

# Simple PopUpButton that mimics PopUpLabel visuals but adds button interactions
# Features:
# - Uses the same popup.png background
# - Hover/Pressed Scale effects

var original_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	original_scale = scale
	
	# Respect Editor Pivot & Position (Do not touch them on ready)
	# This ensures WYSIWYG (What You See Is What You Get)
	
	# Connect signals for animation
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	# Connect to resize signal to update pivot if size changes dynamically
	resized.connect(_on_resized)

func _on_resized() -> void:
	# Keep pivot centered if content changes size, but don't move position
	pivot_offset = size / 2

# update_pivot function removed to avoid position fighting


func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale * 1.1, 0.15)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale, 0.1)

func _on_button_down() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale * 0.95, 0.05)

func _on_button_up() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale * 1.1, 0.1)
