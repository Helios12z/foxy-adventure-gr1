extends EnemyState

@export var dissolve_wait: float = 1.0
@export var dissolve_time: float = 0.7

var _started := false

func _enter() -> void:
	obj.change_animation("dead")
	obj.gravity = 700
	obj.velocity.x = 0

	obj.set_hurt_collision(false)
	obj.set_hit_collision(false)
	obj.disable_check_player_in_sight()
	obj.drop_coins()

	_started = false

func _update(delta: float) -> void:
	if _started:
		return
	_started = true

	_run_dissolve()

func _run_dissolve() -> void:
	if "finished_in_temporary_dead" in obj and not obj.finished_in_temporary_dead:
		await get_tree().create_timer(dissolve_wait).timeout
		obj.queue_free()
		return

	await get_tree().create_timer(dissolve_wait).timeout

	var sprite: AnimatedSprite2D = obj.animated_sprite_2d
	if sprite == null:
		obj.queue_free()
		return

	var mat := sprite.material as ShaderMaterial
	if mat == null:
		obj.queue_free()
		return

	mat.set_shader_parameter("progress", 1.0)

	var tw := obj.create_tween()
	tw.tween_method(
		func(v: float) -> void:
			if is_instance_valid(mat):
				mat.set_shader_parameter("progress", v),
		1.0, 0.0, dissolve_time
	)

	await tw.finished
	obj.queue_free()
