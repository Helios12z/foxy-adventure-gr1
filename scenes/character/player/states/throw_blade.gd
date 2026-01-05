extends PlayerState

## State when player throws blade boomerang

var throw_duration: float = 0.3
var elapsed: float = 0.0
var blade_spawned: bool = false
var animation_finished: bool = false

const BLADE_BOOMERANG_SCENE = preload("res://scenes/character/player/skills/blade_boomerang.tscn")

func _enter() -> void:
	elapsed = 0.0
	blade_spawned = false
	animation_finished = false
	
	# Play attack animation (short throw motion)
	obj.change_animation("attack")
	obj.attack_sound.play()
	
	# Connect animation finished signal
	obj.animated_sprite.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)

func _update(delta: float) -> void:
	elapsed += delta
	
	# Spawn blade when animation finishes
	if animation_finished and not blade_spawned:
		_spawn_blade()
		blade_spawned = true
		# Đổi sang HatAnimatedSprite2D (không có blade trong tay)
		obj.set_animated_sprite(obj.get_node("Direction/HatAnimatedSprite2D"))
	
	# Return to previous state after throw animation
	if elapsed >= throw_duration and blade_spawned:
		change_state(fsm.previous_state)

func _on_attack_animation_finished() -> void:
	animation_finished = true

func _spawn_blade() -> void:
	var blade = BLADE_BOOMERANG_SCENE.instantiate()
	
	# Add to scene tree (parent to current scene, not player, so it stays in world)
	obj.get_parent().add_child(blade)
	
	# Set blade active flag on player
	obj.blade_boomerang_active = true
	obj.has_blade = false  # Player không còn blade trong tay
	
	# Launch blade in player's facing direction
	blade.launch(obj, obj.direction)
	
	# Connect returned signal
	blade.returned.connect(_on_blade_returned)

func _on_blade_returned() -> void:
	obj.blade_boomerang_active = false
	obj.has_blade = true  # Player có blade trở lại
	# Đổi lại BladeAnimatedSprite2D (có blade trong tay)
	obj.set_animated_sprite(obj.get_node("Direction/BladeAnimatedSprite2D"))

func _exit() -> void:
	# Disconnect signal nếu còn connect
	if obj.animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		obj.animated_sprite.animation_finished.disconnect(_on_attack_animation_finished)
