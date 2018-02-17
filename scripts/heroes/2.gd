extends "res://scripts/player.gd"

var is_repelling = false
var overlap_charge = 2

func _process(delta):
	if is_network_master():
		if Input.is_action_just_pressed("hero_2_switch_gravity"):
			# Press button twice to cancel
			rpc("switch_gravity")
			is_repelling = !is_repelling
			if is_repelling:
				get_node("MasterOnly/Crosshair").set_text("/\\")
			else:
				get_node("MasterOnly/Crosshair").set_text("\\/")

		print(get_node("Area").get_overlapping_bodies())
		var overlapping = get_node("Area").get_overlapping_bodies().size()
		switch_charge += delta * overlap_charge * overlapping

sync func switch_gravity():
	var area = get_node("Area")
	area.set_gravity(-area.get_gravity())
