extends HTTPRequest

var is_update_payload = false
var save_to
var time = 0
var size
export var domain = "http://ipv4.cosinegaming.com"

func _ready():
	connect("request_completed", self, "_request_completed")
	# Check if we need an update
	request(domain + "/static/vanagloria/version.json", [], false)
	set_process(true)

func _request_completed(result, response_code, headers, body):
	if result != RESULT_SUCCESS:
		util.log("ERROR: COULD NOT UPDATE. RESULT #" + str(result))
		completed()
		return
	if not is_update_payload:
		# Just checking if we need an update
		var server = JSON.parse(body.get_string_from_utf8()).result
		# 0.0.0 -> Update-shell application, needs more resources
		if server.version == util.version and util.version != "0.0.0":
			util.log("Game up-to-date! Launching")
			completed()
		else:
			is_update_payload = true
			save_to = server.save_location
			if server.has('size'):
				size = server.size
			use_threads = true
			util.log("Need to update! Downloading " + server.download_path)
			request(domain + server.download_path)
	else:
		util.log("Update recieved. Saving to " + save_to)
		var file = File.new()
		file.open(save_to, File.WRITE)
		file.store_buffer(body)
		file.close()
		restart()

func _process(delta):
	var progress
	if size:
		progress = get_downloaded_bytes() / size
	else:
		time += delta
		var fake_progress = 1 - (0.8 / time)
		progress = fake_progress
	get_node("../ProgressBar").value = 100*progress

func restart():
	# Pass on args to new instance, then quit
	var output = []
	OS.execute("./vanagloria", [], false, output) # Mirror just runs godot again
	get_tree().quit()

func completed():
	get_tree().change_scene("res://scenes/menu.tscn")

