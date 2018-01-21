extends "res://scripts/player.gd"

const wallride_speed = 0
const wallride_speed_necessary = 15
const wallride_leap_height = 20
const wallride_leap_side = 10

var since_on_wall = 0
var last_wall_normal = Vector3()
var wallride_forgiveness = .150

func control_player(state):
	.control_player(state)
	wallride(state)

func wallride(state):

	var ray = get_node("Ray")
	var vel = get_linear_velocity()

	# If our feet aren't touching, but we are colliding, we are wall-riding
	if !ray.is_colliding() and get_colliding_bodies() and vel.length() > wallride_speed_necessary:
		since_on_wall = 0
		last_wall_normal = state.get_contact_local_normal()
	else:
		since_on_wall += delta

	if since_on_wall < wallride_forgiveness:
		var aim = get_node("Yaw").get_global_transform().basis
		# Add zero gravity
		set_gravity_scale(0)
		# Allow jumping (for wall hopping!)
		if Input.is_action_just_pressed("jump"):
			var jump_impulse = -wallride_leap_side * last_wall_normal
			jump_impulse.y += wallride_leap_height
			state.apply_impulse(Vector3(), jump_impulse)
	else:
		# We need to return to falling (we aren't riding anymore)
		set_gravity_scale(1)

