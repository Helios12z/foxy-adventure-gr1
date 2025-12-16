# BossAnchor.gd
extends Marker2D

@export var index: int = 7

func _ready() -> void:
	add_to_group("BossAnchor")
