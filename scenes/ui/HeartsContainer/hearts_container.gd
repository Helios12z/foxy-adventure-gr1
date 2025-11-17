extends HBoxContainer

@onready var HeartGuiClass = preload("res://scenes/ui/HeartsContainer/heartGUI.tscn")
@onready var NoHeartGuiClass = preload("res://scenes/ui/HeartsContainer/noHeartGUI.tscn")

func _ready() -> void:
	pass

func setMaxHearts(maxheart: int):
	for i in range(maxheart):
		var heart = HeartGuiClass.instantiate()
		add_child(heart)

func updateHearts(currentHeart: int):
	var hearts = get_children()
	for i in range(currentHeart):
		hearts[i].update(true)
	for i in range(currentHeart, hearts.size()):
		hearts[i].update(false)
	
