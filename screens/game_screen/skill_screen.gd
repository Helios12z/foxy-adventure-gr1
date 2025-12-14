extends Control

# Exported variables for customization
@export_group("Skill Level 1")
@export_multiline var level_1_description: String = "Skill Level 1\nDefault Skill"

@export_group("Skill Level 2")
@export_multiline var level_2_description: String = "Skill Level 2\nUnlock Shield"
@export var level_2_cost: int = 100

@export_group("Skill Level 3")
@export_multiline var level_3_description: String = "Skill Level 3\nUnlock Meteor"
@export var level_3_cost: int = 200

@onready var close_button: TextureButton = $NinePatchRect/CloseTextureButton
@onready var skill_susanoo: Control = $NinePatchRect/SkillSusanoo

# Level 1 Nodes
@onready var lvl1_root: Control = $NinePatchRect/SkillSusanoo/Level1
@onready var lvl1_desc: Label = $NinePatchRect/SkillSusanoo/Level1/Description
@onready var lvl1_icon: TextureRect = $NinePatchRect/SkillSusanoo/Level1/Icon
@onready var lvl1_overlay: TextureRect = $NinePatchRect/SkillSusanoo/Level1/Overlay
@onready var lvl1_btn: Button = $NinePatchRect/SkillSusanoo/Level1/Button
@onready var lvl1_cost: Label = $NinePatchRect/SkillSusanoo/Level1/Cost
@onready var lvl1_coin: TextureRect = $NinePatchRect/SkillSusanoo/Level1/Coin

# Level 2 Nodes
@onready var lvl2_root: Control = $NinePatchRect/SkillSusanoo/Level2
@onready var lvl2_desc: Label = $NinePatchRect/SkillSusanoo/Level2/Description
@onready var lvl2_icon: TextureRect = $NinePatchRect/SkillSusanoo/Level2/Icon
@onready var lvl2_overlay: TextureRect = $NinePatchRect/SkillSusanoo/Level2/Overlay
@onready var lvl2_btn: Button = $NinePatchRect/SkillSusanoo/Level2/Button
@onready var lvl2_cost: Label = $NinePatchRect/SkillSusanoo/Level2/Cost
@onready var lvl2_coin: TextureRect = $NinePatchRect/SkillSusanoo/Level2/Coin

# Level 3 Nodes
@onready var lvl3_root: Control = $NinePatchRect/SkillSusanoo/Level3
@onready var lvl3_desc: Label = $NinePatchRect/SkillSusanoo/Level3/Description
@onready var lvl3_icon: TextureRect = $NinePatchRect/SkillSusanoo/Level3/Icon
@onready var lvl3_overlay: TextureRect = $NinePatchRect/SkillSusanoo/Level3/Overlay
@onready var lvl3_btn: Button = $NinePatchRect/SkillSusanoo/Level3/Button
@onready var lvl3_cost: Label = $NinePatchRect/SkillSusanoo/Level3/Cost
@onready var lvl3_coin: TextureRect = $NinePatchRect/SkillSusanoo/Level3/Coin

@onready var current_coins_label: Label = $NinePatchRect/Coins/Label

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect upgrade buttons
	lvl2_btn.pressed.connect(_on_upgrade_to_2_pressed)
	lvl3_btn.pressed.connect(_on_upgrade_to_3_pressed)
	
	# Listen for player signals
	if GameManager.player:
		GameManager.player.susanoo_level_changed.connect(_on_level_changed)
	
	# Listen for coin signals
	var inventory = GameManager.inventory_system
	if inventory:
		inventory.coin_changed.connect(_on_coin_changed)
		_on_coin_changed(inventory.get_gold())
	
	# Setup initial text from exports
	lvl1_desc.text = level_1_description
	lvl2_desc.text = level_2_description
	lvl2_cost.text = str(level_2_cost)
	lvl3_desc.text = level_3_description
	lvl3_cost.text = str(level_3_cost)
	
	# Level 1 always hides upgrade button/cost as per requirements
	lvl1_btn.hide()
	lvl1_cost.hide()
	lvl1_coin.hide()
	
	update_ui()

func update_ui() -> void:
	var current_level = 0
	if GameManager.player:
		current_level = GameManager.player.susanoo_level
	
	var current_gold = 0
	if GameManager.inventory_system:
		current_gold = GameManager.inventory_system.get_gold()
	
	# Level 1 State
	if current_level >= 1:
		lvl1_icon.show()
		lvl1_overlay.hide()
	else:
		lvl1_icon.hide()
		lvl1_overlay.show()
	
	# Level 2 State
	if current_level >= 2:
		lvl2_icon.show()
		lvl2_overlay.hide()
		# Hide upgrade UI if already unlocked
		lvl2_btn.hide()
		lvl2_cost.hide()
		lvl2_coin.hide()
	else:
		lvl2_icon.hide()
		lvl2_overlay.show()
		# Show upgrade UI ONLY if previous level is active
		if current_level == 1:
			# Always show cost details
			lvl2_cost.show()
			lvl2_coin.show()
			
			# Check coin for button visibility
			if current_gold >= level_2_cost:
				lvl2_btn.show()
			else:
				lvl2_btn.hide()
		else:
			lvl2_btn.hide()
			lvl2_cost.hide()
			lvl2_coin.hide()

	# Level 3 State
	if current_level >= 3:
		lvl3_icon.show()
		lvl3_overlay.hide()
		lvl3_btn.hide()
		lvl3_cost.hide()
		lvl3_coin.hide()
	else:
		lvl3_icon.hide()
		lvl3_overlay.show()
		if current_level == 2:
			# Always show cost details
			lvl3_cost.show()
			lvl3_coin.show()
			
			# Check coin for button visibility
			if current_gold >= level_3_cost:
				lvl3_btn.show()
			else:
				lvl3_btn.hide()
		else:
			lvl3_btn.hide()
			lvl3_cost.hide()
			lvl3_coin.hide()

func _on_close_pressed() -> void:
	queue_free()

func _on_upgrade_to_2_pressed() -> void:
	var inventory = GameManager.inventory_system
	if inventory:
		if inventory.spend_gold(level_2_cost):
			GameManager.player.upgrade_susanoo_level()
			update_ui()
		else:
			print("Not enough gold for Level 2!")

func _on_upgrade_to_3_pressed() -> void:
	var inventory = GameManager.inventory_system
	if inventory:
		if inventory.spend_gold(level_3_cost):
			GameManager.player.upgrade_susanoo_level()
			update_ui()
		else:
			print("Not enough gold for Level 3!")

func _on_level_changed(new_level: int) -> void:
	update_ui()

func _on_coin_changed(new_amount: int) -> void:
	current_coins_label.text = str(new_amount)
	update_ui()
