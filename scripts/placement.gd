extends Node # Networking functionality

var player

var is_placing = false
var placing_node
var placed = []
var max_placed = 5

var start_action
var confirm_action
var delete_action

var scene

signal start_placement
signal confirm_placement

func _init(parent, scene_path):
	player = parent
	player.add_child(self)
	# Set the network master to the player's network master, which happens to be its name
	# This allows it to use master, slave keywords appropriately
	set_network_master(int(player.get_name()))
	scene = load(scene_path)

func place_input(radius=-1):

	# We allow you to just click to place, without needing to press E
	var confirm = Input.is_action_just_pressed(confirm_action)

	if Input.is_action_just_pressed(start_action) or (confirm and not is_placing):
		# Press button twice to cancel
		if is_placing:
			# We changed our mind, delete the placing wall
			placing_node.queue_free()
			is_placing = false
		else:
			# Make a floating placement wall
			placing_node = create()
			is_placing = true

	if Input.is_action_just_pressed(delete_action):
		var pick = player.pick_from(placed)
		if pick != -1:
			rpc("remove_placed", pick)

	if is_placing or confirm:
		position_placement(placing_node)
		if radius > 0: # A radius is specified
			var distance = placing_node.get_translation() - player.get_translation()
			if distance.length() > radius:
				placing_node.out_of_range()
				confirm = false
			else:
				placing_node.within_range()

	if confirm:
		# Order matters here: confirm_placement resets placing_node so we have to do anything with it first
		rpc("slave_place", placing_node.transform)
		confirm_placement(placing_node)

func confirm_placement(node, tf=null):
	if tf:
		node.set_transform(tf)
	node.place()
	placed.append(node)
	check_count()
	placing_node = null
	is_placing = false

func check_count():
	# If we've made max_walls, remove the first we made
	if placed.size() > max_placed:
		placed[0].queue_free()
		placed.pop_front()
	# When placing, make the about-to-disappear wall translucent
	if placed.size() >= max_placed:
		placed[0].make_last()

# Find the point we're looking at, and put the wall there
func position_placement(node):
	var aim = player.get_node("Yaw/Pitch").get_global_transform().basis
	var look_ray = player.get_node("TPCamera/Camera/Ray")
	var pos = look_ray.get_collision_point()
	node.set_translation(pos)
	var normal = look_ray.get_collision_normal()
	var towards = normal + pos
	var up = aim[2] # Wall should be horizontal to my view
	# This helps nearly horizontal walls be easier to make flat
	# We have two methods I'm deciding between
	var use_method_two = true
	if not use_method_two:
		# Method one: only allow horizontal or vertical, based on whether the surface faces you
		var on_wall_margin = 0.75
		if normal.dot(Vector3(0,1,0)) < on_wall_margin:
			var margin = 0.8
			if up.dot(normal) > margin: # The wall is facing us
				# We want flat
				up = Vector3(0,1,0)
			else:
				# We want straight
				up.y = 0
	else:
		# Method two: Make y more aggressive than other dimensions
		up.y = 3 * tanh(up.y)
	up = up.normalized()
	node.look_at(towards, up)

func clear():
	for node in placed:
		node.queue_free()
	placed = []

slave func slave_place(tf):
	var node = create()
	confirm_placement(node, tf)

sync func remove_placed(index):
	placed[index].queue_free()
	placed.remove(index)

func create():
	var node = scene.instance()
	player.get_node("/root/Level").add_child(node)
	# We have to call_deferred because we're `load`ing instead of `preload`ing. TODO: preload?
	node.init(player)
	return node

