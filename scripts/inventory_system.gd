extends Node
class_name InvetorySystem

signal coin_changed(new_amount: int)
signal item_collected(item_type: String, amount: int)
signal key_changed(new_amount: int)
signal heal_potion_changed(new_amount: int)

var coins: int = 0
var keys: int = 0
var heal_potions: int = 0

func _ready() -> void:
	pass
	
func add_coin(amount: int) -> void:
	coins += amount
	coin_changed.emit(coins)
	item_collected.emit("coin", amount)
	GameManager.update_inventory_in_checkpoint()
	print("Collected ", amount, " coins. Total: ", coins)
	
func add_key(_amount: int = 1) -> void:
	keys += _amount
	key_changed.emit(keys)
	item_collected.emit("key", _amount)
	GameManager.update_inventory_in_checkpoint()
	print("Collected ", _amount, " key Total: ", keys)

func add_heal_potion(amount: int = 1) -> void:
	heal_potions += amount
	heal_potion_changed.emit(heal_potions)
	item_collected.emit("heal_potion", amount)
	GameManager.update_inventory_in_checkpoint()
	print("Collected ", amount, " heal potion Total: ", heal_potions)
	
func use_heal_potion() -> bool:
	if has_heal_potion():
		heal_potions -= 1
		heal_potion_changed.emit(heal_potions)
		if Engine.has_singleton("GameManager"):
			GameManager.update_inventory_in_checkpoint()
		return true
	return false
	
	
func use_key() -> bool:
	if has_key():
		keys -= 1
		key_changed.emit(keys)
		if Engine.has_singleton("GameManager"):
			GameManager.update_inventory_in_checkpoint()
		return true
	return false
	
func has_heal_potion() -> bool:
	return heal_potions > 0	

func has_key() -> bool:
	return keys > 0	
	
func get_gold() -> int:
	return coins

func get_keys() -> int:
	return keys

func get_heal_potion() -> int:
	return heal_potions
	
func save_data() -> Dictionary:
	return {
		"coins": coins,
		"keys" : keys,
		"heal_potions": heal_potions
	}

	
