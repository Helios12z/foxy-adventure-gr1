@tool
extends PanelContainer
class_name PopUpLabel

@export_multiline var text: String = "TEXT":
	set(value):
		text = value
		if label:
			label.text = value

@onready var label: Label = $Label

func _ready():
	label.text = text
