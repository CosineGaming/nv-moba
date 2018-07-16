extends Control

# The interface to the actual mumble client written in Python
onready var mumble = get_node("Mumble")
onready var speakers_node = get_node("Speakers")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	mumble.connect(str(networking.port), _get_mumble_id())

func _get_mumble_id():
	return str(get_tree().get_network_unique_id())

func _get_nickname(id):
	var data = networking.players[int(id)]
	return data.username

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

