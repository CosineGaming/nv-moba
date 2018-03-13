extends HTTPRequest

var is_update_payload = false
var save_to
var time = 0

func _ready():
	connect("request_completed", self, "_request_completed")
	# Check if we need an update
	request("http://localhost:8080/vanagloria/version")
	set_process(true)

func _request_completed(result, response_code, headers, body):
	if result != RESULT_SUCCESS:
		print("ERROR: COULD NOT UPDATE. RESULT #" + str(result))
		completed()
		return
	if not is_update_payload:
		# Just checking if we need an update
		var server = JSON.parse(body.get_string_from_utf8()).result
		if server.version == util.version:
			completed()
		else:
			is_update_payload = true
			save_to = server.save_location
			request(server.download_path)
	else:
		var file = File.new()
		file.open(save_to, File.WRITE)
		file.store_buffer(body)
		file.close()
		restart()

func _process(delta):
	time += delta
	var fake_progress = 1 - (0.8 / time)
	get_node("../ProgressBar").value = 100*fake_progress

func restart():
	# Pass on args to new instance, then quit
	var output = []
	OS.execute("./vanagloria", [], false, output) # Mirror just runs godot again
	get_tree().quit()

func completed():
	get_tree().change_scene("res://scenes/lobby.tscn")

