extends EnemyState

@export var duration: float = 3.0
@export var scale_up_time: float = 0.3
@export var scale_down_time: float = 0.3

var seaweed_scene: PackedScene = preload("res://scenes/enemies/serpent_eel/seeweed.tscn")
var seaweed: Node = null
var player: Node = null
var _player_locked: bool = false
var _lock_pos: Vector2 = Vector2.ZERO
var _end_hooked: bool = false
var _ha_conn: bool = false

func _enter() -> void:
	obj.change_animation("attacking")
	obj.start_attack_cooldown()
	timer = duration
	_spawn_seaweed()

func _update(delta: float) -> void:
	if _player_locked and player != null:
		if is_instance_valid(player):
			(player as CharacterBody2D).velocity = Vector2.ZERO
			(player as Node2D).global_position = _lock_pos
	if update_timer(delta):
		_finish_attacking()

func _finish_attacking() -> void:
	_cleanup_seaweed(true)
	obj.change_animation("end_attack")
	var spr = obj.animated_sprite_2d
	if spr != null and not _end_hooked:
		if not spr.animation_finished.is_connected(_on_end_attack_finished):
			spr.animation_finished.connect(_on_end_attack_finished)
			_end_hooked = true

func _exit() -> void:
	if _end_hooked:
		var spr = obj.animated_sprite_2d
		if spr != null and spr.animation_finished.is_connected(_on_end_attack_finished):
			spr.animation_finished.disconnect(_on_end_attack_finished)
	_end_hooked = false
	_cleanup_seaweed(true)

func _spawn_seaweed() -> void:
	var p := _get_player()
	if p == null:
		return
	var pos := (p as Node2D).global_position
	var y := pos.y
	var state := obj.get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0, 1000))
	params.exclude = [obj, p]
	var res := state.intersect_ray(params)
	if res.has("position"):
		y = res["position"].y
	seaweed = seaweed_scene.instantiate()
	var parent := obj.get_tree().current_scene
	if parent == null:
		parent = obj.get_parent()
	parent.add_child(seaweed)
	(seaweed as Node2D).global_position = Vector2(pos.x, y)
	var tw := obj.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(seaweed, "scale", Vector2(1, 1), scale_up_time)
	var ha := seaweed.get_node_or_null("HitArea2D")
	if ha and not _ha_conn:
		ha.connect("hitted", Callable(self, "_on_seaweed_area_entered"))
		_ha_conn = true

func _on_seaweed_area_entered(area: Area2D) -> void:
	if seaweed == null or not is_instance_valid(seaweed):
		return
	var root := _find_character_body_root(area)
	if root != null and root is Player:
		player = root
		(player as BaseCharacter).set_ignore_gravity(true)
		(player as BaseCharacter).stop_move()
		var sw := seaweed as Node2D
		if sw != null:
			_lock_pos = sw.global_position
		_player_locked = true
		var spr := seaweed.get_node_or_null("AnimatedSprite2D")
		if spr:
			(spr as AnimatedSprite2D).play("lock")

func take_damage(_damage_dir: Vector2, damage: int) -> void:
	_cleanup_seaweed(true)
	obj.take_damage(damage)
	if obj.health <= 0:
		change_state(fsm.states.dead)
		return
	obj.set_meta("force_hurt_return_state", "walk")
	change_state(fsm.states.hurt)

func _find_character_body_root(area: Area2D) -> Node:
	var p := area.get_parent()
	if p:
		var gp := p.get_parent()
		if gp and gp is CharacterBody2D:
			return gp
		if p and p is CharacterBody2D:
			return p
	return null

func _get_player() -> Node:
	if Engine.has_singleton("GameManager"):
		return GameManager.player
	return obj.get_tree().get_first_node_in_group("Player")

func _on_end_attack_finished() -> void:
	if obj.animated_sprite_2d.animation == "end_attack":
		change_state(fsm.states.walk)

func _cleanup_seaweed(force_free: bool) -> void:
	if _player_locked and player != null and is_instance_valid(player):
		(player as BaseCharacter).set_ignore_gravity(false)
		_player_locked = false
	if seaweed != null and is_instance_valid(seaweed):
		var ha := seaweed.get_node_or_null("HitArea2D")
		if ha and _ha_conn and ha.is_connected("hitted", Callable(self, "_on_seaweed_area_entered")):
			ha.disconnect("hitted", Callable(self, "_on_seaweed_area_entered"))
		_ha_conn = false
		if force_free:
			(seaweed as Node).queue_free()
	seaweed = null
