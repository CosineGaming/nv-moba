extends "res://scripts/player.gd"

var time = 0

func _ready():
	._ready()
	read_recording()

func _physics_process(delta):
	time += delta

func _integrate_forces(state):
	play_keys(state)

func read_recording():

	# Gather all existing recordings
	var possible = []
	var begin = "%d-%d" % [player_info.level, player_info.hero]
	var path = "res://recordings/"
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var fname = dir.get_next()
		print(fname)
		if fname == "":
			# Indicates end of directory
			break
		if fname.begins_with(begin):
			possible.append(fname)
	dir.list_dir_end()

	# Now pick a random one
	var fname = possible[randi() % possible.size()]

	# Read the file into recording.events for later use
	var frec = File.new()
	frec.open(path + fname, File.READ)
	recording = parse_json(frec.get_as_text())
	frec.close()

func play_keys(phys_state):
	# states[0] is first state
	# states[0][0] is first state's time
	while float(recording[0][0]) <= time:
		# states[0][1] is first state's STATE
		var state = recording.pop_front()[1]
		for i in range(state.size()):
			state[i] = str2var(state[i])
		set_status(state)
	phys_state.integrate_forces()
