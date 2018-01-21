extends "res://scripts/player.gd"

const wallride_speed = 0
const wallride_speed_necessary = 15
const wallride_leap_height = 10
const wallride_leap_side = 10

var since_on_wall = 0
var last_wall_normal = Vector3()
var wallride_forgiveness = .150

func control_player(delta):
	wallride(delta)
	.control_player(delta)

func wallride(delta):
	# If our feet aren't touching, but we are colliding, we are wall-riding
	if is_on_wall() and not is_on_floor() and velocity.length() > wallride_speed_necessary:
		since_on_wall = 0
		last_wall_normal = get_slide_collision(0).normal
	else:
		since_on_wall += delta
	if since_on_wall < wallride_forgiveness:
		var aim = get_node("Yaw").get_global_transform().basis
		# Add zero gravity
		velocity.y = -gravity # So it's undone in super
		# Allow jumping (for wall hopping!)
		if Input.is_action_just_pressed("jump"):
			velocity.y += wallride_leap_height
			velocity += wallride_leap_side * last_wall_normal
