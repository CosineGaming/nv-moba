extends "res://scripts/player.gd"

const wallride_speed_necessary = 1.5
const wallride_leap_height = 45
const wallride_leap_side = 6
const wallride_leap_build = 0

var since_on_wall = 0
var last_wall_normal = Vector3()
var wallride_forgiveness = .3

func _ready():
	._ready()
	walk_speed *= 0.8
	air_accel *= 1.5
	jump_speed *= 1
	air_speed_build *= 2
	# Since movement is the only ability of this hero, it builds charge more
	movement_charge *= 2

func control_player(state):
	var original_speed = walk_speed
	var original_accel = air_accel
	var boost_strength = 2
	var boost_drain = 25 # Recall increased charge must be factored in
	var cost = boost_drain * state.step
	if get_node("MasterOnly/Boost").is_pressed() and charge > cost:
		walk_speed *= 2
		air_accel *= 3
		build_charge(-cost)
	.control_player(state)
	wallride(state)
	walk_speed = original_speed
	air_accel = original_accel

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
			var build_factor = 1 + charge * wallride_leap_build
			var jump_impulse = build_factor * wallride_leap_side * last_wall_normal
			jump_impulse.y += build_factor * wallride_leap_height
			set_gravity_scale(1) # Jumping requires gravity
			state.apply_impulse(Vector3(), jump_impulse * get_mass())
	else:
		# We need to return to falling (we aren't riding anymore)
		set_gravity_scale(1)

	state.integrate_forces()

