extends Area2D

signal charges_changed(left, max)

# Defense hit area: absolute guard against enemies and bullets.
# Spawns a fire shield at the tangent contact point and consumes charges.

var _enabled: bool = true
@export var enabled: bool = true: set = _set_enabled, get = _get_enabled
@export var max_charges: int = 5
@export var defense_damage: int = 1
@export var shield_scene: PackedScene = preload("res://scenes/skills/susanoo/fire_shield.tscn")
@export var enemy_knockback_force: Vector2 = Vector2(420, -300)

var _charges_left: int = 0

func _ready() -> void:
	_charges_left = max_charges
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_set_enabled(enabled)
	charges_changed.emit(_charges_left, max_charges)

func _on_area_entered(area: Area2D) -> void:
	if not _enabled or _charges_left <= 0:
		return
	# Compute contact point and outward normal
	var cp := _compute_contact(area.global_position)
	# If HurtArea2D (enemy), apply hurt + push out by direction
	if area.has_method("take_damage"):
		# Only react when the enemy area actually has an active collision
		if _has_active_collision(area):
			var dir: Vector2 = (area.global_position - global_position).normalized()
			area.take_damage(dir, defense_damage)
			# Push the enemy farther away when hurt
			var enemy := _find_character_body_root(area)
			if enemy and enemy is CharacterBody2D:
				var cb := enemy as CharacterBody2D
				cb.velocity.x = sign(dir.x) * abs(enemy_knockback_force.x)
				cb.velocity.y = enemy_knockback_force.y
			_spawn_shield(cp.pos, cp.normal)
			_consume_charge()
			return
	# If bullet area (child of bullet), try to remove parent bullet
	var parent := area.get_parent()
	if parent and parent is RigidBody2D:
		_spawn_shield(cp.pos, cp.normal)
		parent.queue_free()
		_consume_charge()

func _on_body_entered(body: Node) -> void:
	if not _enabled or _charges_left <= 0:
		return
	# If a rigid body bullet enters directly
	if body is RigidBody2D:
		var cp := _compute_contact(body.global_position)
		_spawn_shield(cp.pos, cp.normal)
		(body as RigidBody2D).queue_free()
		_consume_charge()

func _compute_contact(other_pos: Vector2) -> Dictionary:
	var vec: Vector2 = (other_pos - global_position)
	var shape := get_node_or_null("CollisionShape2D")
	if shape and shape.shape is RectangleShape2D:
		var rect := shape.shape as RectangleShape2D
		var half := rect.size * 0.5
		var dir := vec.normalized()
		var pos: Vector2 = global_position
		var normal: Vector2 = Vector2.ZERO
		if abs(dir.x) > abs(dir.y):
			pos.x += sign(dir.x) * half.x
			normal = Vector2(sign(dir.x), 0)
		else:
			pos.y += sign(dir.y) * half.y
			normal = Vector2(0, sign(dir.y))
		return {"pos": pos, "normal": normal}
	elif shape and shape.shape is CircleShape2D:
		var r: float = (shape.shape as CircleShape2D).radius
		var n := vec.normalized()
		return {"pos": global_position + n * r, "normal": n}
	else:
		var n2 := vec.normalized()
		return {"pos": global_position + n2 * 24.0, "normal": n2}

func _spawn_shield(pos: Vector2, normal: Vector2) -> void:
	if shield_scene == null:
		return
	# Nhích khiên lên trên một chút để không lún xuống nền
	pos += Vector2(0, -20)
	var shield := shield_scene.instantiate()
	get_tree().current_scene.add_child(shield)
	shield.global_position = pos
	# Xoay rời rạc theo pháp tuyến để tránh lộn sprite khi va chạm bên trái
	var rot := 0.0
	if abs(normal.x) > abs(normal.y):
		rot = 0.0 if normal.x > 0.0 else PI
	else:
		rot = -PI / 2.0 if normal.y < 0.0 else PI / 2.0
	shield.rotation = rot
	# Fade out smoothly then free
	var sprite := shield.get_node_or_null("Sprite2D")
	if sprite:
		# Tạo tween trên chính shield để tự hủy độc lập với Susanoo
		var tw := shield.create_tween()
		tw.set_parallel(false)
		tw.tween_property(sprite, "modulate:a", 0.8, 0.06)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
		tw.tween_callback(Callable(shield, "queue_free"))
	else:
		shield.queue_free()

func _set_enabled(v: bool) -> void:
	_enabled = v
	var shape := get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = not v
	monitoring = v

func _get_enabled() -> bool:
	return _enabled

func _consume_charge() -> void:
	_charges_left -= 1
	if _charges_left <= 0:
		var shape := get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = true
		monitoring = false
	charges_changed.emit(max(0, _charges_left), max_charges)

func get_charges_left() -> int:
	return _charges_left

func get_max_charges() -> int:
	return max_charges

func _find_character_body_root(area: Area2D) -> Node:
	var p := area.get_parent()
	if p:
		var gp := p.get_parent()
		if gp and gp is CharacterBody2D:
			return gp
		if p and p is CharacterBody2D:
			return p
	return null

func _has_active_collision(n: Node) -> bool:
	# Detect any enabled CollisionShape2D/CollisionPolygon2D within the node subtree
	if n is CollisionShape2D:
		var cs := n as CollisionShape2D
		return not cs.disabled and cs.shape != null
	if n is CollisionPolygon2D:
		var cp := n as CollisionPolygon2D
		return not cp.disabled
	for c in n.get_children():
		if _has_active_collision(c):
			return true
	return false
