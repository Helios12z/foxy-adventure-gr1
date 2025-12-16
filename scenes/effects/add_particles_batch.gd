@tool
extends EditorScript

## Helper script to add HitParticleEffect to all characters in a directory
## Usage: 
## 1. Open this script in Godot Editor
## 2. Modify TARGET_DIR to point to your characters directory
## 3. Run script from Script Editor (File → Run)

const TARGET_DIR = "res://scenes/enemies/"  # Change this to your target directory
const PARTICLE_SCENE_PATH = "res://scenes/effects/HitParticleEffect.tscn"

func _run():
	print("=== Adding HitParticleEffect to characters ===")
	
	# Verify particle scene exists
	if not ResourceLoader.exists(PARTICLE_SCENE_PATH):
		print("ERROR: Particle scene not found at: ", PARTICLE_SCENE_PATH)
		return
	
	var particle_scene = load(PARTICLE_SCENE_PATH)
	if particle_scene == null:
		print("ERROR: Failed to load particle scene")
		return
	
	# Process all .tscn files in target directory
	_process_directory(TARGET_DIR)
	
	print("=== Done! ===")

func _process_directory(dir_path: String):
	var dir = DirAccess.open(dir_path)
	if dir == null:
		print("ERROR: Cannot open directory: ", dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir_path.path_join(file_name)
		
		# Recursively process subdirectories
		if dir.current_is_dir() and not file_name.begins_with("."):
			_process_directory(full_path)
		# Process .tscn files
		elif file_name.ends_with(".tscn"):
			_add_particle_to_scene(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _add_particle_to_scene(scene_path: String):
	print("\nProcessing: ", scene_path)
	
	# Load the scene
	var scene = load(scene_path) as PackedScene
	if scene == null:
		print("  ⚠ Failed to load scene")
		return
	
	var root = scene.instantiate()
	if root == null:
		print("  ⚠ Failed to instantiate scene")
		return
	
	# Check if this is a BaseCharacter
	if not (root.get_script() and root.get_script().get_base_script() and 
			(root.get_script().get_base_script().resource_path.ends_with("base_character.gd") or
			 root.get_script().resource_path.ends_with("base_character.gd"))):
		print("  ⏭ Skipped (not a BaseCharacter)")
		root.queue_free()
		return
	
	# Check if particle effect already exists
	var has_particle = false
	for child in root.get_children():
		if child.name == "HitParticleEffect":
			has_particle = true
			break
	
	# Also check in Direction node
	if not has_particle and root.has_node("Direction"):
		var direction_node = root.get_node("Direction")
		for child in direction_node.get_children():
			if child.name == "HitParticleEffect":
				has_particle = true
				break
	
	if has_particle:
		print("  ⏭ Already has HitParticleEffect")
		root.queue_free()
		return
	
	# Add HitParticleEffect
	var particle_scene = load(PARTICLE_SCENE_PATH)
	var particle_instance = particle_scene.instantiate()
	particle_instance.name = "HitParticleEffect"
	
	# Add to Direction node if exists, otherwise to root
	if root.has_node("Direction"):
		root.get_node("Direction").add_child(particle_instance)
		particle_instance.owner = root
	else:
		root.add_child(particle_instance)
		particle_instance.owner = root
	
	# Enable hit particles in character
	if "enable_hit_particles" in root:
		root.enable_hit_particles = true
	
	# Pack and save the scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, scene_path)
	
	print("  ✓ Added HitParticleEffect and enabled particles")
	root.queue_free()
