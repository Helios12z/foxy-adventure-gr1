extends BaseCharacter


@export var player_path: NodePath
@onready var player: Node2D = get_node_or_null(player_path)
@onready var sprite: AnimatedSprite2D = $Direction/AnimatedSprite2D

var anchors: Array[Node2D] = []
@export var anchor_move_time := 0.5

@export var eruption_duration := 1.5

func _ready() -> void:
	gravity = 0
	super._ready()

	await get_tree().process_frame
	_init_anchors_from_room()

	fsm = FSM.new(self, $States, $States/Phase1, true)


func _physics_process(delta: float) -> void:
	fsm._update(delta)

	if player:
		var dx := player.global_position.x - global_position.x
		if abs(dx) > 1.0:
			sprite.flip_h = dx < 0


func _init_anchors_from_room() -> void:
	anchors.clear()

	var nodes := get_tree().get_nodes_in_group("BossAnchor")
	if nodes.is_empty():
		push_error("Boss3: Khong tim thay BossAnchor nao trong room")
		return

	# sort theo index trong BossAnchor.gd
	nodes.sort_custom(func(a, b):
		var ia = a.index if a.has_variable("index") else 0
		var ib = b.index if b.has_variable("index") else 0
		return ia < ib
	)

	for n in nodes:
		anchors.append(n)

	if anchors.size() < 5:
		push_warning("Boss3: anchors.size() = %d (<5), kiem tra room" % anchors.size())


func move_to_anchor(index: int) -> void:
	if anchors.is_empty():
		push_error("Boss3: anchors rong, quen config BossAnchor trong room")
		return

	index = clamp(index, 0, anchors.size() - 1)
	var target := anchors[index].global_position

	if global_position == target:
		return

	var tween := create_tween()
	tween.tween_property(self, "global_position", target, anchor_move_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished

func do_eruption_wave() -> void:
	await move_to_anchor(1) # CenterHigh

	sprite.play("cast_eruption")
	await get_tree().create_timer(0.6).timeout

	for w in get_tree().get_nodes_in_group("WaterEruption"):
		if w.has_method("play"):
			w.play()
	await get_tree().create_timer(0.4).timeout

	sprite.play("recover")
	await get_tree().create_timer(0.5).timeout


func do_water_pagoda() -> void:
	await move_to_anchor(0) # LeftHigh
	sprite.play("cast_pagoda")
	await get_tree().create_timer(0.7).timeout
	for w in get_tree().get_nodes_in_group("WaterPagoda"):
		if w.has_method("play"):
			w.play()
	await get_tree().create_timer(0.6).timeout
	sprite.play("recover")
	await get_tree().create_timer(0.5).timeout

# ... tương tự cho water_pillar (về anchor 3), vase_water (anchor 2), water_ball (anchor 4)
