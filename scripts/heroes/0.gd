extends "res://scripts/player.gd"

const wallride_speed = 0.5
const wallride_speed_necessary = 15

func control_player(delta):
	wallride(delta)
	.control_player(delta)

func wallride(delta):
	# If our feet aren't touching, but we are colliding, we are wall-riding
	if is_on_wall() and velocity.length() > wallride_speed_necessary:
		var aim = get_node("Yaw").get_global_transform().basis
		var direction = Vector3()
		if Input.is_action_pressed("move_forwards"):
			direction -= aim[2]
		if Input.is_action_pressed("move_backwards"):
			direction += aim[2]
		velocity += direction * wallride_speed
		velocity.y = -gravity # So it's undone in super
	else:
		pass
		# We need to return to falling (we aren't riding anymore)
