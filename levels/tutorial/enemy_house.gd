extends StaticBody2D

signal destroyed

@export var max_hp: int = 5
var hp: int

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hurt: Area2D = $HurtArea2D

func _ready() -> void:
	hp = max_hp
	if _hurt and _hurt.has_signal("hurt"):
		# Kết nối đúng chữ ký: (direction: Vector2, damage: float)
		_hurt.connect("hurt", Callable(self, "_on_hurt"))
	_update_anim()

func _on_hurt(_direction: Vector2, damage: float) -> void:
	# Nhận damage chuẩn từ HitArea2D
	hp -= int(damage)
	if hp <= 0:
		hp = 0
		_on_destroyed()
	else:
		_flash_red()
		_update_anim()

func _update_anim() -> void:
	if hp <= 0:
		_sprite.play("destroyed")
	elif hp < 3:
		_sprite.play("damaged_2")
	elif hp < 5:
		_sprite.play("damaged_1")
	else:
		_sprite.play("normal")

func _on_destroyed() -> void:
	_update_anim()
	collision_layer = 0
	collision_mask = 0
	destroyed.emit()
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 3.0)
	tween.finished.connect(Callable(self, "queue_free"))

func is_destroyed() -> bool:
	return hp <= 0

func _flash_red() -> void:
	if _sprite == null:
		return
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "modulate", Color(1, 0.25, 0.25, 1.0), 0.08)
	t.tween_property(_sprite, "modulate", Color(1, 1, 1, 1.0), 0.15)
