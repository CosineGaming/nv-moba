extends "res://scripts/player.gd"

#func _ready():
#	get_node("Area").set_gravity_distance_scale(10)

func _process(delta):
	print(get_translation())
	#get_node("Area").set_gravity_vector(get_translation())
