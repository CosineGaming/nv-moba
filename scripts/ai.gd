extends Node

var recording
var time
var set_spawn = true

func _ready():
	if is_network_master():
		read_recording()
		set_spawn = true
		time = 0
		set_physics_process(true)

func _physics_process(delta):
	if is_network_master():
		if set_spawn:
			get_node("..").set_translation(str2var(recording.spawn))
			get_node("..").switch_charge = str2var(recording.switch_charge)
			set_spawn = false
		play_keys()
		# It's actually better to do this 2nd
		# Since input is, on average, called 1/2way through a frame
		time += delta

func read_recording():

	# Gather all existing recordings
	var possible = []
	var begin = "%d-%d" % [get_node("..").player_info.level, get_node("..").player_info.hero]
	var path = "res://recordings/"
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var fname = dir.get_next()
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

func apply_dict(from, to):
	if typeof(from) != TYPE_DICTIONARY:
		return from
	else:
		for key in from:
			to[key] = apply_dict(from[key], to[key])
		return to

func obj_to_event(d):
	var e
	if d.type == "motion": e = InputEventMouseMotion.new()
	if d.type == "key": e = InputEventKey.new()
	if d.type == "mb": e = InputEventMouseButton.new()
	d.erase("type") # Not in the event
	apply_dict(d, e)
	return e

func play_keys():
	# events[0] is first event
	# events[0][0] is first event's TIME
	if recording.events.size() == 0:
		get_node("..").spawn() # This may cause spawn twice, I hope this isn't a problem
		# get_node("..").switch_charge = 0 # This needs to reset so the recording is accurate
		read_recording()
	while float(recording.events[0][0]) <= time:
		# events[0][1] is first event's EVENT
		var event_obj = recording.events.pop_front()[1]
		var event = obj_to_event(event_obj)
		Input.parse_input_event(event)
		#._input(event)
		#get_node("TPCamera")._input(event)
