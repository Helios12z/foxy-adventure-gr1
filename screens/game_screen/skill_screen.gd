extends Control

# Exported variables for customization
@export_group("Susanoo Skill Level 1")
@export_multiline var susanoo_level_1_description: String = "Susanoo Level 1\nDefault Skill"

@export_group("Susanoo Skill Level 2")
@export_multiline var susanoo_level_2_description: String = "Susanoo Level 2\nUnlock Shield"
@export var susanoo_level_2_cost: int = 100

@export_group("Susanoo Skill Level 3")
@export_multiline var susanoo_level_3_description: String = "Susanoo Level 3\nUnlock Meteor"
@export var susanoo_level_3_cost: int = 200

@export_group("Room Skill Level 1")
@export_multiline var room_level_1_description: String = "Room Skill 1\nDefault"
@export_group("Room Skill Level 2")
@export_multiline var room_level_2_description: String = "Room Skill 2\nUnlock Bubble"
@export var room_level_2_cost: int = 150
@export_group("Room Skill Level 3")
@export_multiline var room_level_3_description: String = "Room Skill 3\nUnlock Prison"
@export var room_level_3_cost: int = 300

@onready var skill_room: Control = $NinePatchRect/SkillRoom

# Room Level 1 Nodes
@onready var room_lvl1_root: Control = $NinePatchRect/SkillRoom/Level1
@onready var room_lvl1_desc: Label = $NinePatchRect/SkillRoom/Level1/Description
@onready var room_lvl1_icon: TextureRect = $NinePatchRect/SkillRoom/Level1/Icon
@onready var room_lvl1_overlay: TextureRect = $NinePatchRect/SkillRoom/Level1/Overlay
@onready var room_lvl1_btn: Button = $NinePatchRect/SkillRoom/Level1/Button
@onready var room_lvl1_cost: Label = $NinePatchRect/SkillRoom/Level1/Cost
@onready var room_lvl1_coin: TextureRect = $NinePatchRect/SkillRoom/Level1/Coin

# Room Level 2 Nodes
@onready var room_lvl2_root: Control = $NinePatchRect/SkillRoom/Level2
@onready var room_lvl2_desc: Label = $NinePatchRect/SkillRoom/Level2/Description
@onready var room_lvl2_icon: TextureRect = $NinePatchRect/SkillRoom/Level2/Icon
@onready var room_lvl2_overlay: TextureRect = $NinePatchRect/SkillRoom/Level2/Overlay
@onready var room_lvl2_btn: Button = $NinePatchRect/SkillRoom/Level2/Button
@onready var room_lvl2_cost: Label = $NinePatchRect/SkillRoom/Level2/Cost
@onready var room_lvl2_coin: TextureRect = $NinePatchRect/SkillRoom/Level2/Coin

# Room Level 3 Nodes
@onready var room_lvl3_root: Control = $NinePatchRect/SkillRoom/Level3
@onready var room_lvl3_desc: Label = $NinePatchRect/SkillRoom/Level3/Description
@onready var room_lvl3_icon: TextureRect = $NinePatchRect/SkillRoom/Level3/Icon
@onready var room_lvl3_overlay: TextureRect = $NinePatchRect/SkillRoom/Level3/Overlay
@onready var room_lvl3_btn: Button = $NinePatchRect/SkillRoom/Level3/Button
@onready var room_lvl3_cost: Label = $NinePatchRect/SkillRoom/Level3/Cost
@onready var room_lvl3_coin: TextureRect = $NinePatchRect/SkillRoom/Level3/Coin

@onready var close_button: TextureButton = $NinePatchRect/CloseTextureButton
@onready var skill_susanoo: Control = $NinePatchRect/SkillSusanoo

# Susanoo Level 1 Nodes
@onready var susanoo_lvl1_root: Control = $NinePatchRect/SkillSusanoo/Level1
@onready var susanoo_lvl1_desc: Label = $NinePatchRect/SkillSusanoo/Level1/Description
@onready var susanoo_lvl1_icon: TextureRect = $NinePatchRect/SkillSusanoo/Level1/Icon
@onready var susanoo_lvl1_overlay: TextureRect = $NinePatchRect/SkillSusanoo/Level1/Overlay
@onready var susanoo_lvl1_btn: Button = $NinePatchRect/SkillSusanoo/Level1/Button
@onready var susanoo_lvl1_cost: Label = $NinePatchRect/SkillSusanoo/Level1/Cost
@onready var susanoo_lvl1_coin: TextureRect = $NinePatchRect/SkillSusanoo/Level1/Coin

# Susanoo Level 2 Nodes
@onready var susanoo_lvl2_root: Control = $NinePatchRect/SkillSusanoo/Level2
@onready var susanoo_lvl2_desc: Label = $NinePatchRect/SkillSusanoo/Level2/Description
@onready var susanoo_lvl2_icon: TextureRect = $NinePatchRect/SkillSusanoo/Level2/Icon
@onready var susanoo_lvl2_overlay: TextureRect = $NinePatchRect/SkillSusanoo/Level2/Overlay
@onready var susanoo_lvl2_btn: Button = $NinePatchRect/SkillSusanoo/Level2/Button
@onready var susanoo_lvl2_cost: Label = $NinePatchRect/SkillSusanoo/Level2/Cost
@onready var susanoo_lvl2_coin: TextureRect = $NinePatchRect/SkillSusanoo/Level2/Coin

# Susanoo Level 3 Nodes
@onready var susanoo_lvl3_root: Control = $NinePatchRect/SkillSusanoo/Level3
@onready var susanoo_lvl3_desc: Label = $NinePatchRect/SkillSusanoo/Level3/Description
@onready var susanoo_lvl3_icon: TextureRect = $NinePatchRect/SkillSusanoo/Level3/Icon
@onready var susanoo_lvl3_overlay: TextureRect = $NinePatchRect/SkillSusanoo/Level3/Overlay
@onready var susanoo_lvl3_btn: Button = $NinePatchRect/SkillSusanoo/Level3/Button
@onready var susanoo_lvl3_cost: Label = $NinePatchRect/SkillSusanoo/Level3/Cost
@onready var susanoo_lvl3_coin: TextureRect = $NinePatchRect/SkillSusanoo/Level3/Coin

@onready var current_coins_label: Label = $NinePatchRect/Coins/Label

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

	# Connect Susanoo upgrade buttons
	susanoo_lvl2_btn.pressed.connect(_on_upgrade_to_2_pressed)
	susanoo_lvl3_btn.pressed.connect(_on_upgrade_to_3_pressed)

	# Connect Room upgrade buttons
	room_lvl2_btn.pressed.connect(_on_room_upgrade_to_2_pressed)
	room_lvl3_btn.pressed.connect(_on_room_upgrade_to_3_pressed)

	# Listen for player signals
	if GameManager.player:
		GameManager.player.susanoo_level_changed.connect(_on_level_changed)
		GameManager.player.room_level_changed.connect(_on_level_changed)

	# Listen for coin signals
	var inventory = GameManager.inventory_system
	if inventory:
		inventory.coin_changed.connect(_on_coin_changed)
		_on_coin_changed(inventory.get_gold())

	# Setup initial text Susanoo
	susanoo_lvl1_desc.text = susanoo_level_1_description
	susanoo_lvl2_desc.text = susanoo_level_2_description
	susanoo_lvl2_cost.text = str(susanoo_level_2_cost)
	susanoo_lvl3_desc.text = susanoo_level_3_description
	susanoo_lvl3_cost.text = str(susanoo_level_3_cost)

	# Level 1 always hides upgrade button/cost
	susanoo_lvl1_btn.hide()
	susanoo_lvl1_cost.hide()
	susanoo_lvl1_coin.hide()

	# Setup initial text Room
	room_lvl1_desc.text = room_level_1_description
	room_lvl2_desc.text = room_level_2_description
	room_lvl2_cost.text = str(room_level_2_cost)
	room_lvl3_desc.text = room_level_3_description
	room_lvl3_cost.text = str(room_level_3_cost)

	# Room Level 1 always hides upgrade
	room_lvl1_btn.hide()
	room_lvl1_cost.hide()
	room_lvl1_coin.hide()

	# Pause the game when screen opens
	get_tree().paused = true

	update_ui()

func update_ui() -> void:
	var current_level_sus = 0
	var current_level_room = 0
	if GameManager.player:
		current_level_sus = GameManager.player.susanoo_level
		current_level_room = GameManager.player.room_level

	var current_gold = 0
	if GameManager.inventory_system:
		current_gold = GameManager.inventory_system.get_gold()

	_update_susanoo_tree(current_level_sus, current_gold)
	_update_room_tree(current_level_room, current_gold)

func _update_susanoo_tree(current_level: int, current_gold: int) -> void:
	# Level 1 State
	if current_level >= 1:
		susanoo_lvl1_icon.show()
		susanoo_lvl1_overlay.hide()
	else:
		susanoo_lvl1_icon.hide()
		susanoo_lvl1_overlay.show()

	# Level 2 State
	if current_level >= 2:
		susanoo_lvl2_icon.show()
		susanoo_lvl2_overlay.hide()
		susanoo_lvl2_btn.hide()
		susanoo_lvl2_cost.hide()
		susanoo_lvl2_coin.hide()
	else:
		susanoo_lvl2_icon.hide()
		susanoo_lvl2_overlay.show()
		if current_level == 1:
			susanoo_lvl2_cost.show()
			susanoo_lvl2_coin.show()
			if current_gold >= susanoo_level_2_cost:
				susanoo_lvl2_btn.show()
			else:
				susanoo_lvl2_btn.hide()
		else:
			susanoo_lvl2_btn.hide()
			susanoo_lvl2_cost.hide()
			susanoo_lvl2_coin.hide()

	# Level 3 State
	if current_level >= 3:
		susanoo_lvl3_icon.show()
		susanoo_lvl3_overlay.hide()
		susanoo_lvl3_btn.hide()
		susanoo_lvl3_cost.hide()
		susanoo_lvl3_coin.hide()
	else:
		susanoo_lvl3_icon.hide()
		susanoo_lvl3_overlay.show()
		if current_level == 2:
			susanoo_lvl3_cost.show()
			susanoo_lvl3_coin.show()
			if current_gold >= susanoo_level_3_cost:
				susanoo_lvl3_btn.show()
			else:
				susanoo_lvl3_btn.hide()
		else:
			susanoo_lvl3_btn.hide()
			susanoo_lvl3_cost.hide()
			susanoo_lvl3_coin.hide()

func _update_room_tree(current_level: int, current_gold: int) -> void:
	# Level 1
	if current_level >= 1:
		room_lvl1_icon.show()
		room_lvl1_overlay.hide()
	else:
		room_lvl1_icon.hide()
		room_lvl1_overlay.show()

	# Level 2
	if current_level >= 2:
		room_lvl2_icon.show()
		room_lvl2_overlay.hide()
		room_lvl2_btn.hide()
		room_lvl2_cost.hide()
		room_lvl2_coin.hide()
	else:
		room_lvl2_icon.hide()
		room_lvl2_overlay.show()
		if current_level == 1:
			room_lvl2_cost.show()
			room_lvl2_coin.show()
			if current_gold >= room_level_2_cost:
				room_lvl2_btn.show()
			else:
				room_lvl2_btn.hide()
		else:
			room_lvl2_btn.hide()
			room_lvl2_cost.hide()
			room_lvl2_coin.hide()

	# Level 3
	if current_level >= 3:
		room_lvl3_icon.show()
		room_lvl3_overlay.hide()
		room_lvl3_btn.hide()
		room_lvl3_cost.hide()
		room_lvl3_coin.hide()
	else:
		room_lvl3_icon.hide()
		room_lvl3_overlay.show()
		if current_level == 2:
			room_lvl3_cost.show()
			room_lvl3_coin.show()
			if current_gold >= room_level_3_cost:
				room_lvl3_btn.show()
			else:
				room_lvl3_btn.hide()
		else:
			room_lvl3_btn.hide()
			room_lvl3_cost.hide()
			room_lvl3_coin.hide()

func _on_close_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _on_upgrade_to_2_pressed() -> void:
	var inventory = GameManager.inventory_system
	if inventory:
		if inventory.spend_gold(susanoo_level_2_cost):
			GameManager.player.upgrade_susanoo_level()
			update_ui()

func _on_upgrade_to_3_pressed() -> void:
	var inventory = GameManager.inventory_system
	if inventory:
		if inventory.spend_gold(susanoo_level_3_cost):
			GameManager.player.upgrade_susanoo_level()
			update_ui()

# Room Upgrade Handlers
func _on_room_upgrade_to_2_pressed() -> void:
	var inventory = GameManager.inventory_system
	if inventory:
		if inventory.spend_gold(room_level_2_cost):
			GameManager.player.upgrade_room_level()
			update_ui()

func _on_room_upgrade_to_3_pressed() -> void:
	var inventory = GameManager.inventory_system
	if inventory:
		if inventory.spend_gold(room_level_3_cost):
			GameManager.player.upgrade_room_level()
			update_ui()

func _on_level_changed(new_level: int) -> void:
	update_ui()

func _on_coin_changed(new_amount: int) -> void:
	current_coins_label.text = str(new_amount)
	update_ui()
