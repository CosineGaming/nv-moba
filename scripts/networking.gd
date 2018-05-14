extends Node

onready var matchmaking = preload("res://scripts/matchmaking.gd").new()

var players = []
# TODO: Should we abstract server so variables like this aren't cluttering everything up?
var players_done = []
var begun = false
# TODO: This needs to go. It carries nothing of value
# ALL server negotiation should happen before ANY data is investigated (in lobby)
var my_info = {}

func _ready():
	add_child(matchmaking)

	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")

# func connect_global_server(): TODO
# 	ip = global_server_ip
# 	_client_init()

func start_client(ip, port):
	# collect_info() TODO
	var peer = NetworkedMultiplayerENet.new()
	print("Connecting to " + ip + ":" + str(port))
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	# get_node("CustomGame/Client").set_text("Clienting!") TODO

# func singleplayer_init(): TODO
# 	# collect_info() TODO
# 	var peer = NetworkedMultiplayerENet.new()
# 	peer.create_server(port, 1)
# 	get_tree().set_network_peer(peer)
# 	players[1] = my_info
# 	start_game()

func _connect_to_matchmaker(game_port):
	var matchmaker_peer = StreamPeerTCP.new()
	matchmaker_peer.connect_to_host("127.0.0.1", matchmaking.SERVER_TO_SERVER_PORT)
	var matchmaker_tcp = PacketPeerStream.new()
	matchmaker_tcp.set_stream_peer(matchmaker_peer)
	matchmaker_tcp.put_var(matchmaking.messages.ready_to_connect)
	matchmaker_tcp.put_var(game_port)

func start_server(port):
	# collect_info() TODO
	var peer = NetworkedMultiplayerENet.new()
	print("Starting server on port " + str(port))
	peer.create_server(port, matchmaking.GAME_SIZE)
	get_tree().set_network_peer(peer)
	# As soon as we're listening, let the matchmaker know
	_connect_to_matchmaker(port)
	# is_connected = true TODO
	# get_node("CustomGame/Server").set_text("Serving!")
	# get_node("JoinedGameLobby").show()
	# if server_playing:
	# 	players[1] = my_info
	# if "start_game" in my_info and my_info.start_game: TODO
	# 	start_game()

# sync func start_game(): TODO
	# my_info.level = get_node("CustomGame/LevelSelect").get_selected_id() TODO
	# rpc("_pre_configure_game", my_info.level)

func disconnect_player(id):
	if get_tree().is_network_server():
		rpc("unregister_player", id)
	# call_deferred("render_player_list") TODO

func connect_player():
	rpc("_register_player", get_tree().get_network_unique_id(), {})
	if util.args.get_value("-start-game"):
		rpc_id(1, "start_game")
	# is_connected = true TODO

remote func _register_player(new_peer, info):
	players[new_peer] = info
	render_player_list()
	if (get_tree().is_network_server()):
		var right_team_count = 0
		# Send current players' info to new player
		for old_peer in players:
			# Send new player, old player's info
			rpc_id(new_peer, "_register_player", old_peer, players[old_peer])
			if old_peer != new_peer:
				# We need to assign team later, so count current
				if players[old_peer].is_right_team:
					right_team_count += 1
				# You'd think this part could be met with a simple `rpc(`, but actually it can't
				# My best guess is this is because we haven't registered the names yet, but I'm not sure (TODO)
				if old_peer != 1:
					# Send old player, new player's info (not us, no infinite loop)
					rpc_id(old_peer, "_register_player", new_peer, info)
				if begun:
					rpc_id(old_peer, "_spawn_player", new_peer)
					rpc_id(old_peer, "_begin_player_deferred", new_peer) # Spawning is deferred
		# if not server_playing: TODO
		# 	# We didn't catch this in players
		# 	rpc_id(1, "_spawn_player", new_peer)
		# 	rpc_id(1, "_begin_player_deferred", new_peer) # Spawning is deferred
		var assign_right_team = right_team_count * 2 < players.size()
		rpc("assign_team", new_peer, assign_right_team)
		if not begun and players.size() == matchmaking.GAME_SIZE:
			start_game()
		if begun:
			rpc_id(new_peer, "_pre_configure_game", my_info.level)
			rpc_id(new_peer, "_post_configure_game")

sync func _unregister_player(peer):
	players.erase(peer)
	get_node("/root/Level/Players/%d" % peer).queue_free()

sync func _spawn_player(p):
	var hero = players[p].hero
	var player = load("res://scenes/heroes/" + str(hero) + ".tscn").instance()
	player.set_name(str(p))
	player.set_network_master(p)
	player.players = players[p]
	get_node("/root/Level/Players").call_deferred("add_child", player)

sync func _pre_configure_game(level):
	begun = true
	my_info.level = level # Remember the level for future player registration

	var self_peer_id = get_tree().get_network_unique_id()

	# Remove the interface so as to not fuck with things
	# But we still need the lobby alive to deal with networking!
	for element in get_node("/root/Lobby").get_children():
		element.queue_free()

	var world = load("res://scenes/levels/%d.tscn" % level).instance()
	get_node("/root").add_child(world)

	# Load all players (including self)
	for p in players:
		players[p].level = level
		spawn_player(p)

	rpc_id(1, "done_preconfiguring", self_peer_id)

sync func _done_preconfiguring(who):
	players_done.append(who)
	if players_done.size() == players.size():
		# We call deferred in case singleplayer has placing the player in queue still
		call_deferred("rpc", "post_configure_game")

sync func _post_configure_game():
	# Begin all players (including self)
	for p in players:
		_begin_player_deferred(p)

func _begin_player(peer):
	get_node("/root/Level/Players/%d" % peer).begin()

remote func _begin_player_deferred(peer):
	call_deferred("_begin_player", peer)

sync func reset_state():
	players_done = []
	get_node("/root/Level").queue_free()

