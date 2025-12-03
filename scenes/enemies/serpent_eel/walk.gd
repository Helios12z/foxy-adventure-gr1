extends EnemyState

var _prev_material: Material = null
var _mat: ShaderMaterial = null
var _t: float = 0.0
@export var squash_amp: float = 0.12
@export var squash_freq: float = 1.6

func _enter() -> void:
	obj.change_animation("walk")
	var spr = obj.animated_sprite_2d
	if spr != null:
		_prev_material = spr.material
		var sh := Shader.new()
		sh.code = "shader_type canvas_item; uniform float squash = 0.0; void vertex(){ float s = clamp(squash, -0.6, 0.6); vec2 c = vec2(0.5, 0.5); VERTEX -= (c); VERTEX.y *= (1.0 - s); VERTEX.x *= (1.0 + s*0.25); VERTEX += (c); } void fragment(){ COLOR = texture(TEXTURE, UV); }"
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		spr.material = _mat

func _update(delta):
	obj.velocity.x = obj.direction * 50
	_t += delta
	if _mat != null:
		var s = abs(sin(_t * squash_freq)) * squash_amp
		_mat.set_shader_parameter("squash", s)
	if obj.can_detect_player() and obj.attack_cooldown_timer <= 0.0:
		change_state(fsm.states.attack)
	if _should_turn_around():
		obj.turn_around()

func _exit() -> void:
	var spr = obj.animated_sprite_2d
	if spr != null:
		if _prev_material != null:
			spr.material = _prev_material
		else:
			spr.material = null
	_mat = null


func _should_turn_around() -> bool:
	if obj.is_touch_wall():
		return true
	if obj.is_on_floor() and obj.is_can_fall():
		return true
	return false
