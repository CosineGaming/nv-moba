extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var SERVER_IP = "127.0.0.1"
var SERVER_PORT = 2467
var MAX_PLAYERS = 2
var SERVER_PLAYING = true

var player_info = {}
var my_info = {}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_node("Server").connect("pressed", self, "_server_init")
	get_node("Client").connect("pressed", self, "_client_init")
	get_node("Singleplayer").connect("pressed", self, "_singleplayer_init")
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("connected_to_server", self, "_connected_ok")

func _client_init():
	my_info.username = get_node("Username").get_text()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().set_network_peer(peer)
	get_node("Client").set_text("Clienting!")
	
func _singleplayer_init():
	my_info.username = get_node("Username").get_text()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, 1)
	get_tree().set_network_peer(peer)
	player_info[1] = my_info
	pre_configure_game()

func _server_init():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	get_node("Server").set_text("Serving!")
	if SERVER_PLAYING:
		player_info[1] = my_info

func _player_connected(id):
	print("Connect, my friend: " + str(id))

func _connected_ok():
	rpc("register_player", get_tree().get_network_unique_id(), my_info)

remote func register_player(id, info):
	player_info[id] = info
	if (get_tree().is_network_server()):
		# Send current players' info to new player
		rpc_id(id, "register_player", 1, my_info)
		for peer_id in player_info:
			rpc_id(id, "register_player", peer_id, player_info[peer_id])
		if (player_info.size() == MAX_PLAYERS):
			rpc("pre_configure_game")
			if SERVER_PLAYING:
				pre_configure_game()

var players_done = []
remote func done_preconfiguring(who):
	players_done.append(who)
	if (players_done.size() == player_info.size()):
		rpc("post_configure_game")

remote func pre_configure_game():
	var self_peer_id = get_tree().get_network_unique_id()
	
	get_node("/root/Control").queue_free()
	var world = load("res://world.tscn").instance()
	get_node("/root").add_child(world)
	
	# Load all players (including self)
	for p in player_info:
		var player = preload("res://player.tscn").instance()
		player.set_name(str(p))
		player.set_network_master(p)
		get_node("/root/world/players").add_child(player)
	
	rpc_id(1, "done_preconfiguring", self_peer_id)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
