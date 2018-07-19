extends Control

# The interface to the actual mumble client written in Python
onready var mumble = get_node("Mumble")
onready var speakers_node = get_node("Speakers")
onready var textbox = get_node("Layer/Enter")
onready var chatlog = get_node("Layer/Chat")
onready var bg = get_node("Layer/Solid")

var hide_bg_timer = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	mumble.connect_to_server(str(networking.port), _get_mumble_id())
	textbox.connect("text_entered", self, "_send_message")

func _get_mumble_id():
	return str(get_tree().get_network_unique_id())

func _get_nickname(id):
	var data = networking.players[int(id)]
	return data.username

func _send_message(text):
	# Unfortunately this callback is called WHENEVER we press enter, even if
	# not focused. Checking the focus prevents us from sending empty messages
	# when trying to focus, and releasing focus immediately after gaining
	if textbox.has_focus():
		textbox.release_focus()
		util.get_master_player().call_deferred("toggle_mouse_capture")
		# Only send message if we've typed, otherwise we're just exiting
		if text:
			# Pymumble doesn't support text messages "from" fields, so we have to
			# do it manually :(
			var our_nick = _get_nickname(get_tree().get_network_unique_id())
			var fulltext = "<%s> %s" % [our_nick, text]
			mumble.send_message(fulltext)
	textbox.text = ""

func _input(input):
	if input.is_action_pressed("focus_chat"):
		# We need to check if we have focus cause we don't wanna refocus when we're trying to DEfocus
		if not textbox.has_focus():
			# We'll release immediately unless we call deferred and wait for the
			# _send_message has_focus check
			textbox.call_deferred("grab_focus")
			util.get_master_player().call_deferred("toggle_mouse_capture")

func _process(delta):
	var speaking = mumble.get_speaking()
	for child in speakers_node.get_children():
		child.queue_free()
	for i in range(speaking.size()):
		var id = speaking[i]
		var speaker = preload("res://scenes/mumble_speaking.tscn").instance()
		speaker.get_node("Speaker").text = _get_nickname(id)
		speaker.rect_position = Vector2(0, 60 * i)
		speakers_node.add_child(speaker)

	var messages = mumble.get_messages()
	var start = 0

	var max_lines = 13
	if textbox.has_focus():
		bg.show()
	else:
		bg.hide()
		# Force it to regrow
		# Changing rect size to 0 breaks grow direction
		chatlog.margin_top = 10000000
		start = max(0, messages.size() - max_lines)

	var text = ""
	for i in range(start, messages.size()):
		# We grow upwards, so add the newline to the beginning
		text += "\n" + messages[i]
	chatlog.text = text

