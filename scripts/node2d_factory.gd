extends Marker2D
class_name Node2DFactory

signal created(product)

@export var product_packed_scene: PackedScene
@export var target_container_name: StringName

func create(_product_packed_scene := product_packed_scene) -> Node2D:
	if _product_packed_scene == null:
		return null
	var product: Node2D = _product_packed_scene.instantiate()
	product.global_position = global_position

	var container := _resolve_container()
	if container == null:
		var root := get_tree().current_scene
		container = root if root != null else get_parent()
	if container == null:
		container = self

	container.add_child(product)
	created.emit(product)
	return product

func _resolve_container() -> Node:
	# Prefer a named container at the scene root
	if target_container_name != StringName():
		var root := get_tree().current_scene
		if root != null:
			var found := root.find_child(target_container_name, true, false)
			if found != null:
				return found
	# Search upward through parents for a matching child
	var n: Node = self
	while n != null:
		var p := n.get_parent()
		if p != null and target_container_name != StringName():
			var c := p.find_child(target_container_name, true, false)
			if c != null:
				return c
		n = p
	return null
	
