extends EnemyState

var death_timer: float = 0.0
var animation_finished: bool = false

func _enter() -> void:
	obj.change_animation("dead")
	obj.boss_music.stop()
	death_timer = 0.0
	animation_finished = false
	obj.attack_collision_shape_2d.disabled = true
	obj.hurt_collision_shape_2d.disabled = true
	obj.hit_collision_shape_2d.disabled = true

func _update(_delta: float) -> void:
	if not animation_finished and not obj.animated_sprite_2d.is_playing():
		animation_finished = true

	if animation_finished:
		death_timer += _delta
		if death_timer >= 1.0:
			obj.emit_signal("boss_died")
			obj.queue_free()
