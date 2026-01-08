extends CanvasLayer

@onready var texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	# Initial State
	texture_rect.modulate.a = 0.0
	
	# Appear
	var tw = create_tween()
	tw.tween_property(texture_rect, "modulate:a", 1.0, 0.5)
	
	# Blink Loop (Smooth Pulse)
	var blink_tw = create_tween().set_loops()
	blink_tw.tween_property(texture_rect, "modulate:a", 0.3, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	blink_tw.tween_property(texture_rect, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Auto remove after 7 seconds
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(7.0).timeout
	if not is_inside_tree(): return
	
	blink_tw.kill()
	var out_tw = create_tween()
	out_tw.tween_property(texture_rect, "modulate:a", 0.0, 1.0)
	out_tw.tween_callback(queue_free)
