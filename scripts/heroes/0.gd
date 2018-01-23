extends "res://scripts/player.gd"

const wallride_speed_necessary = 2
const wallride_leap_height = 14
const wallride_leap_side = 8

var since_on_wall = 0
var last_wall_normal = Vector3()
var wallride_forgiveness = .150

func _ready():
	._ready()
	walk_speed *= 1.5

func control_player(state):
	.control_player(state)
	wallride(state)

func wallride(state):

	var ray = get_node("Ray")
	var vel = state.get_linear_velocity()

	# If our feet aren't touching, but we are colliding, we are wall-riding
	if !ray.is_colliding() and get_colliding_bodies() and vel.length() > wallride_speed_necessary:
		last_wall_normal = state.get_contact_local_normal(0)
		# Make sure it isn't the floor
		if last_wall_normal.dot(Vector3(0,1,0)) < 0.95:
			since_on_wall = 0
	else:
		since_on_wall += state.get_step()

	debug_node.set_text(str(since_on_wall < wallride_forgiveness))
	if since_on_wall < wallride_forgiveness:
		# Add zero gravity
		set_gravity_scale(0)
		# Remove any momentum we may have
		state.set_linear_velocity(Vector3(vel.x, 0, vel.z))
		# Because 1/2 of our energy is wasted in the wall, get more forwards/backwards here:
		var aim = get_node("Yaw").get_global_transform().basis
		if Input.is_action_pressed("move_forwards"):
			apply_impulse(Vector3(), -air_accel * aim[2] * get_mass())
		if Input.is_action_pressed("move_backwards"):
			apply_impulse(Vector3(), air_accel * aim[2] * get_mass())
		# Allow jumping (for wall hopping!)
		if Input.is_action_just_pressed("jump"):
			var jump_impulse = wallride_leap_side * last_wall_normal
			jump_impulse.y += wallride_leap_height
			set_gravity_scale(1) # Jumping requires gravity
			state.apply_impulse(Vector3(), jump_impulse * get_mass())
	else:
		# We need to return to falling (we aren't riding anymore)
		set_gravity_scale(1)

	state.integrate_forces()

