extends Node

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	
func _ready() -> void:
	#$Player.spike_collision.connect(_set_spike_collision)
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()

func _set_spike_collision(enable :bool):
	var spikes = find_children("Spike", "Node", true, false)
	for s in spikes:
		s.set_collision(enable)
