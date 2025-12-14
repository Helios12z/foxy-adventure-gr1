extends Node2D

var dialogue_triggered = false

func _ready() -> void:
	$AnimatedSprite2D.play("idle")
	# Initialize the water fairy conversation seen variable if it doesn't exist
	if not Dialogic.VAR.has("WaterFairyConversationSeen"):
		Dialogic.VAR.set("WaterFairyConversationSeen", false)


func _on_area_2d_body_entered(body: Node2D) -> void:
	# Check if it's the player and dialogue hasn't been triggered yet
	if body.is_in_group("player") and not dialogue_triggered:
		dialogue_triggered = true

		# Check if the conversation has been seen before
		if Dialogic.VAR.get("WaterFairyConversationSeen"):
			# Skip the conversation
			print("Water fairy conversation already seen, skipping...")
			return

		# Mark conversation as seen and start dialogue
		Dialogic.VAR.set("WaterFairyConversationSeen", true)
		Dialogic.start("water_fairy_blade")
