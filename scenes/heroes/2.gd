extends "res://scripts/player.gd"

#func _ready():
#	get_node("Area").set_gravity_distance_scale(10)

var is_repelling = false

func _process(delta):
	if Input.is_action_just_pressed("hero_2_switch_gravity"):
		# Press button twice to cancel
		var area = get_node("Area")
		area.set_gravity(-area.get_gravity())
		is_repelling = !is_repelling
		if is_repelling:
			get_node("RepellingHUD").set_text("/\\")
		else:
			get_node("RepellingHUD").set_text("\\/")
	#get_node("Area").set_gravity_vector(get_translation())
