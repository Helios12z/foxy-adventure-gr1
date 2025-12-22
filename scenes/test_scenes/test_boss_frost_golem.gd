extends Node2D

@onready var frost_guardian: CharacterBody2D = $FrostGuardian

func _ready() -> void:
	await get_tree().create_timer(3.0).timeout
	frost_guardian.start_appearing.emit()
