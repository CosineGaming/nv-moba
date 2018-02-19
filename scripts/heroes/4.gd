# Hero 4 stuns people at a distance, removing their linear velocity

extends "res://scripts/player.gd"

# --- Godot overrides ---

func _ready():
	colored_meshes.append("Yaw/Pitch/Beam")

func _process(delta):
	if is_network_master():

		var stun = Input.is_action_pressed("hero_4_stun")
		var is_stunning = false

		if stun:
			var look_ray = get_node("TPCamera/Camera/Ray")
			var stunning = look_ray.get_collider()
			var players = get_node("/root/Level/Players").get_children()
			var player = players.find(stunning)
			if player != -1:
				rpc("stun", players[player].get_name(), look_ray.get_collision_point())
				is_stunning = true

		if not is_stunning:
			rpc("unstun")

# --- Player overrides ---

# --- Own ---

sync func stun(net_id, position):
	print("stunnnn")
	# Stun the thing!
	var player = get_node("/root/Level/Players/%s" % net_id)
	player.set_linear_velocity(Vector3())

	# Show the beam!
	var beam = get_node("Yaw/Pitch/Beam")
	get_node("Yaw/Pitch").look_at(position, Vector3(0,1,0))
	beam.show()
	var us = get_node("TPCamera/Camera").get_global_transform().origin
	var distance = position - us
	beam.scale = Vector3(1,distance.length(),1)
	print(beam.scale)
	# We move the beam up by half the scale because the position is based on the center, not the bottom
	beam.translation.z = -distance.length() / 2 # We face -z direction

sync func unstun():
	var beam = get_node("Yaw/Pitch/Beam")
	beam.hide()

