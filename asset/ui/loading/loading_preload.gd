extends Node

# Preload all loading screen images to ensure they are included in web exports
# This script forces Godot to export these resources even though they're loaded dynamically

# Dark Forest images
var dark_forest_1 = preload("res://asset/ui/loading/loading_content/images/dark_forest/loading_dark_forest_1.png")

# Island images
var island_1 = preload("res://asset/ui/loading/loading_content/images/island/loading_island_1.png")

# King Crab images
var king_crab_1 = preload("res://asset/ui/loading/loading_content/images/king_crab/loading_king_crab_1.png")

# Map 3 images
var map_3_1 = preload("res://asset/ui/loading/loading_content/images/map_3/loading_map3.png")
var map_3_2 = preload("res://asset/ui/loading/loading_content/images/loading_map3.png")

# Tutorial images
var tutorial_1 = preload("res://asset/ui/loading/loading_content/images/tutorial/tutorial_loading_1.png")

# War Lord Turtle images
var war_lord_turtle_1 = preload("res://asset/ui/loading/loading_content/images/war_lord_turtle/loading_war_lord_turtle_1.png")

# Water Priestess images
var water_priestess_1 = preload("res://asset/ui/loading/loading_content/images/water_priestess/loading_water_pri.png")

# Water Goddess/Boss3 images
var boss3_water_goddess = preload("res://asset/ui/loading/loading_content/images/boss3_water_goddess/full_bg.jpg")

# Dictionary for easy access by content key
var preloaded_images: Dictionary = {
	"dark_forest": [dark_forest_1],
	"island": [island_1],
	"king_crab": [king_crab_1],
	"map_3": [map_3_1, map_3_2],
	"tutorial": [tutorial_1],
	"war_lord_turtle": [war_lord_turtle_1],
	"water_priestess": [water_priestess_1],
	"boss3_water_goddess": [boss3_water_goddess]
}

func get_preloaded_images(content_key: String) -> Array[Texture2D]:
	if preloaded_images.has(content_key):
		return preloaded_images[content_key]
	return []
