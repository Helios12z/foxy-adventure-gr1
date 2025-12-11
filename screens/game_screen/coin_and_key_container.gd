extends HBoxContainer

@onready var coin_label: Label = $CoinContainer/CoinLabel
@onready var key_label: Label = $KeyContainer/KeyLabel
@onready var heal_label: Label = $HealContainer/HealLabel
var inventory: InvetorySystem

func _ready():
	# Tìm inventory system trong GameManager
	var gm = get_tree().get_root().get_node("GameManager")
	inventory = gm.get_node("InventorySystem")

	print("HUD Found Inventory:", inventory)

	inventory.coin_changed.connect(_on_coin_changed)
	inventory.key_changed.connect(_on_key_change)
	inventory.heal_potion_changed.connect(_on_heal_change)

	coin_label.text = str(inventory.get_gold())
	key_label.text = str(inventory.get_keys())
	heal_label.text = str(inventory.get_heal_potion())



# Coin thay đổi (chỉ coin)
func _on_coin_changed(new_amount: int) -> void:
	coin_label.text = str(new_amount)


# Khi thu thập item (coin hoặc key)
func _on_key_change(new_amount: int) -> void:
	key_label.text = str(new_amount)
	
func _on_heal_change(new_amount: int) -> void:
	heal_label.text = str(new_amount)
