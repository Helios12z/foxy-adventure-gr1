extends Panel

@onready var heartGui = $heart
@onready var noHeartGui = $noheart

func _ready():
	heartGui.visible = true
	noHeartGui.visible = false
	
func update(whole: bool):
	heartGui.visible = whole
	noHeartGui.visible = not whole
