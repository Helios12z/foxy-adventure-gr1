extends Node2D

@export var lifetime: float = 0.4
@export var enemy_knockback_force: Vector2 = Vector2(420, -300)
@export var paw_damage: int = 1
@export var appear_time: float = 0.12
@export var fade_time: float = 0.22
@export var spawn_offset_x: float = 10.0
@export var spawn_offset_y: float = -30.5
@export var shove_distance: float = 60.0
@export var shove_time: float = 0.18

var player: Player = null
var _paw_area: Area2D = null
var _shape_was_disabled: bool = false
var _sprite: Sprite2D = null

func _ready() -> void:
	# Find player
	if get_parent() is Player:
		player = get_parent() as Player
	else:
		player = GameManager.player
	if player == null:
		queue_free()
		return
	# Flip sprite to player facing
	scale.x = float(player.direction)
	# Place effect slightly ahead of player near PawHitArea2D
	var dir_node := player.get_node_or_null("Direction")
	if dir_node and dir_node is Node2D:
		global_position = (dir_node as Node2D).global_position + Vector2(spawn_offset_x * player.direction, spawn_offset_y)
	else:
		global_position = player.global_position
	# Hook PawHitArea2D of player
	_paw_area = player.get_node_or_null("Direction/PawHitArea2D")
	if _paw_area == null:
		queue_free()
		return
	var shape := _paw_area.get_node_or_null("CollisionShape2D")
	if shape:
		_shape_was_disabled = shape.disabled
		shape.disabled = false
	_paw_area.monitoring = true
	# Set damage for paw hits
	_paw_area.set("damage", paw_damage)
	# Connect signals: use HitArea2D.hitted if available, and body_entered for bullets
	if _paw_area.has_signal("hitted"):
		# Avoid duplicate connections
		if not _paw_area.is_connected("hitted", Callable(self, "_on_paw_hitted")):
			_paw_area.connect("hitted", Callable(self, "_on_paw_hitted"))
			_paw_area.connect("hitted", Callable(self, "_on_paw_hitted"))
	# Body entered neutralizes rigid body bullets
	if not _paw_area.is_connected("body_entered", Callable(self, "_on_body_entered")):
		_paw_area.body_entered.connect(_on_body_entered)

	# Grab sprite and play appear tween
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite:
		var target_a := _sprite.modulate.a
		var c := _sprite.modulate
		c.a = 0.0
		_sprite.modulate = c
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate:a", target_a, appear_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Visual forward shove (small distance, very strong feel) without changing knockback logic
	var start_pos := global_position
	var shove_pos := start_pos + Vector2(shove_distance * player.direction, 0)
	var tw_shove := create_tween()
	tw_shove.set_parallel(true)
	# Fast position shove with Back easing for punchy feel
	tw_shove.tween_property(self, "global_position", shove_pos, shove_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Slight squash via sprite scale to emphasize impact
	if _sprite:
		var base_scale := _sprite.scale
		var impact_scale := Vector2(base_scale.x * 1.08, base_scale.y * 0.92)
		var tw_scale := create_tween()
		tw_scale.set_parallel(true)
		tw_scale.tween_property(_sprite, "scale", impact_scale, shove_time * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_scale.tween_property(_sprite, "scale", base_scale, shove_time * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Lifetime cleanup
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = lifetime
	t.timeout.connect(_on_timeout)
	add_child(t)
	t.start()

func _on_timeout() -> void:
	# Fade out then cleanup
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(Callable(self, "_cleanup_and_free"))
	else:
		_cleanup_and_free()

func _cleanup_and_free() -> void:
	if _paw_area:
		# Restore shape disabled state and disconnects
		var shape := _paw_area.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = _shape_was_disabled
		if _paw_area.has_signal("hitted") and _paw_area.is_connected("hitted", Callable(self, "_on_paw_hitted")):
			_paw_area.disconnect("hitted", Callable(self, "_on_paw_hitted"))
		if _paw_area.is_connected("body_entered", Callable(self, "_on_body_entered")):
			_paw_area.disconnect("body_entered", Callable(self, "_on_body_entered"))
	queue_free()

func _on_paw_hitted(area: Area2D) -> void:
	# If enemy hurt area, push enemy away (damage applied by HitArea2D)
	if area and area.has_method("take_damage"):
		var enemy := _find_character_body_root(area)
		if enemy and enemy is CharacterBody2D:
			var cb := enemy as CharacterBody2D
			# Always knock away in player's facing direction
			var dir_x: float = 0.0
			if player != null:
				dir_x = float(player.direction)
			else:
				# Fallback to relative direction if player missing
				dir_x = sign((area.global_position - global_position).x)
			cb.velocity.x = dir_x * abs(enemy_knockback_force.x)
			cb.velocity.y = enemy_knockback_force.y
		return
	# If bullet (via child area), remove parent rigid body
	var parent := area.get_parent()
	if parent and parent is RigidBody2D:
		(parent as RigidBody2D).queue_free()

func _on_body_entered(body: Node) -> void:
	if body is RigidBody2D:
		(body as RigidBody2D).queue_free()

func _find_character_body_root(area: Area2D) -> Node:
	var p := area.get_parent()
	if p:
		var gp := p.get_parent()
		if gp and gp is CharacterBody2D:
			return gp
		return p
	return null
