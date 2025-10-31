#extends Node
#func _enter_tree() -> void:
	#GameManager.current_stage = self
#
#func _ready() -> void:
	## ⏳ Delay 1 frame cho toàn bộ Portal, TileMap load xong
	#await get_tree().process_frame
	#if not GameManager.respawn_at_portal():
		#GameManager.respawn_at_checkpoint()
