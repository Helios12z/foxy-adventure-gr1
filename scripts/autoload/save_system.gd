extends Node

## Save system for persistent checkpoint data

const SAVE_FILE = "user://checkpoint_save.dat"

# Save checkpoint data to file
func save_checkpoint_data(data: Dictionary) -> void:
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)


		# JSON provides a static method to serialized JSON string.
	var json_string = JSON.stringify(data)

	# Store the save dictionary as a new line in the save file.
	save_file.store_line(json_string)


# Load checkpoint data from file
func load_checkpoint_data() -> Dictionary:
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not save_file:
		return {}
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data
		return node_data
	return {}

# Check if save file exists
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

# Delete save file
func delete_save_file() -> void:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_FILE)
		print("Save file deleted")
