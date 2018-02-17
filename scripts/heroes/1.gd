extends "res://scripts/player.gd"

var walls = []
var placing_wall_node
var is_placing_wall = false

const max_walls = 100

# --- Godot overrides ---

func _process(delta):
	if is_network_master():

		# We allow you to just click to place, without needing to press E
		var place_wall = Input.is_action_just_pressed("hero_1_confirm_wall")

		if Input.is_action_just_pressed("hero_1_place_wall") or (place_wall and not is_placing_wall):
			# Press button twice to cancel
			if is_placing_wall:
				# We changed our mind, delete the placing wall
				placing_wall_node.queue_free()
				is_placing_wall = false
			else:
				# Make a floating placement wall
				placing_wall_node = add_wall()
				is_placing_wall = true

		if Input.is_action_just_pressed("hero_1_remove_wall"):
			var look_ray = get_node("TPCamera/Camera/Ray")
			var removing = look_ray.get_collider()
			var wall = walls.find(removing)
			if wall != -1:
				rpc("remove_wall", wall)

		if is_placing_wall or place_wall:
			position_wall(placing_wall_node)

		if place_wall:
			finalize_wall(placing_wall_node)
			rpc("slave_place_wall", placing_wall_node.get_transform())
			placing_wall_node = null
			is_placing_wall = false

func _exit_tree():
	clear_walls()

# --- Player overrides ---

func spawn():
	.spawn()
	clear_walls()

# --- Own ---

# Find the point we're looking at, and put the wall there
func position_wall(wall):
	var aim = get_node("Yaw/Pitch").get_global_transform().basis
	var look_ray = get_node("TPCamera/Camera/Ray")
	var pos = look_ray.get_collision_point()
	wall.set_translation(pos)
	var normal = look_ray.get_collision_normal()
	var towards = normal + pos
	var up = aim[2] # Wall should be horizontal to my view
	# This helps nearly horizontal walls be easier to make flat
	# We have two methods I'm deciding between
	var use_method_two = true
	if not use_method_two:
		# Method one: only allow horizontal or vertical, based on whether the surface faces you
		var wall_wall_margin = 0.75
		if normal.dot(Vector3(0,1,0)) < wall_wall_margin:
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
	wall.look_at(towards, up)

func clear_walls():
	for wall in walls:
		wall.queue_free()
	walls = []

slave func slave_place_wall(tf):
	var wall = add_wall()
	finalize_wall(wall, tf)

sync func remove_wall(index):
	walls[index].queue_free()
	walls.remove(index)

# Creates wall, adds to world, and returns the node
func add_wall():
	var wall = preload("res://scenes/wall.tscn").instance()
	var friendly = player_info.is_right_team == master_player.player_info.is_right_team
	var color = friend_color if friendly else enemy_color
	get_node("/root/Level").add_child(wall)
	wall.init(self, color)
	return wall

func finalize_wall(wall, tf=null):
	if tf:
		wall.set_transform(tf)
	wall.place()
	# Remember this wall, and return to non-placing state
	# We need to do this even as slave, because we keep track of the count
	walls.append(wall)
	check_wall_count()

func check_wall_count():
	# If we've made max_walls, remove the first we made
	if walls.size() > max_walls:
		walls[0].queue_free()
		walls.pop_front()
	# When placing, make the about-to-disappear wall translucent
	if walls.size() >= max_walls:
		walls[0].make_last()

