extends "res://scripts/player.gd"

var is_repelling = false

func _process(delta):
	if is_network_master():
		if Input.is_action_just_pressed("hero_2_switch_gravity"):
			# Press button twice to cancel
			rpc("switch_gravity")
			is_repelling = !is_repelling
			if is_repelling:
				get_node("RepellingHUD").set_text("/\\")
			else:
				get_node("RepellingHUD").set_text("\\/")

sync func switch_gravity():
	var area = get_node("Area")
	area.set_gravity(-area.get_gravity())
