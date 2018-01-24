extends "res://scripts/player.gd"

var walls = []
var placing_wall_node
var is_placing_wall = false

const max_walls = 3

func _process(delta):
	if is_network_master():
		
		if Input.is_action_just_pressed("hero_1_place_wall"):
			# Press button twice to cancel
			if is_placing_wall:
				# We changed our mind, delete the placing wall
				placing_wall_node.queue_free()
				is_placing_wall = false
			else:
				# Make a floating placement wall
				placing_wall_node = add_wall()
				is_placing_wall = true

		if is_placing_wall:
			# Find the point we're looking at, and put the wall there
			var aim = get_node("Yaw/Pitch").get_global_transform().basis
			var look_ray = get_node("Yaw/Pitch/Ray")
			var pos = look_ray.get_collision_point()
			placing_wall_node.set_translation(pos)
			var towards = look_ray.get_collision_normal() + pos
			var up = -aim[2] # Wall should be horizontal to my view
			placing_wall_node.look_at(towards, up)

			if Input.is_action_just_pressed("hero_1_confirm_wall"):
				finalize_wall(placing_wall_node)
				rpc("slave_place_wall", placing_wall_node.get_transform())
				placing_wall_node = null
				is_placing_wall = false

slave func slave_place_wall(tf):
	var wall = add_wall()
	finalize_wall(wall, tf)

# Creates wall, adds to world, and returns the node
func add_wall():
	var wall = preload("res://scenes/wall.tscn").instance()
	get_node("/root/world").add_child(wall)
	return wall

func finalize_wall(wall, tf=null):
	if tf:
		wall.set_transform(tf)
	# Originally, the wall is disabled to avoid weird physics
	wall.get_node("CollisionShape").disabled = false
	# Remember this wall, and return to non-placing state
	# We need to do this even as slave, because we keep track of the count
	walls.append(wall)
	check_wall_count()

func check_wall_count():
	# If we've made max_walls, remove the first we made
	if walls.size() > max_walls:
		walls[0].queue_free()
		walls.pop_front()