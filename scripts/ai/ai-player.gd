extends "res://scripts/player.gd"

var time = 0

func _ready():
	._ready()
	read_recording()
	print(recording.spawn)
	set_translation(recording.spawn)

func _physics_process(delta):
	time += delta
	play_keys()

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
	print(recording.events)
	frec.close()

func play_keys():
	# events[0] is first event
	# events[0][0] is first event's TIME
	while float(recording.events[0][0]) <= time:
		# events[0][1] is first event's EVENT2
		var event_obj = recording.events.pop_front()[1]
		print(event_obj)
		var event = obj_to_event(event_obj)
		Input.parse_input_event(event)
		#._input(event)
		#get_node("TPCamera")._input(event)
