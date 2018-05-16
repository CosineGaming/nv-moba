extends Node

onready var matchmaking = preload("res://scripts/matchmaking.gd").new()

remote var players = []
# TODO: Should we abstract server so variables like this aren't cluttering everything up?
var players_done = []
var begun = false
# TODO: This needs to go. It carries nothing of value
# ALL server negotiation should happen before ANY data is investigated (in lobby)
var my_info = {
	hero: 0,
	username: "Nickname",
}

func _ready():
	add_child(matchmaking)

	get_tree().connect("network_peer_connected", self, "_register_player")
	get_tree().connect("network_peer_disconnected", self, "disconnect_player")
	# get_tree().connect("connected_to_server", self, "_on_connect")

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

func start_server(port, server_playing=false):
	# collect_info() TODO
	var peer = NetworkedMultiplayerENet.new()
	print("Starting server on port " + str(port))
	peer.create_server(port, matchmaking.GAME_SIZE)
	get_tree().set_network_peer(peer)
	# As soon as we're listening, let the matchmaker know
	_connect_to_matchmaker(port)
	if server_playing:
		players[1] = my_info
	# is_connected = true TODO
	# get_node("CustomGame/Server").set_text("Serving!")
	# get_node("JoinedGameLobby").show()
	# if "start_game" in my_info and my_info.start_game: TODO
	# 	start_game()

sync func start_game(level):
	print(var2str(players))
	rpc("_pre_configure_game", level)

func disconnect_player(id):
	if get_tree().is_network_server():
		rpc("unregister_player", id)
	# call_deferred("render_player_list") TODO

# func _on_connect():
# 	rpc("_register_player", get_tree().get_network_unique_id(), my_info)
# 	if util.args.get_value("-start-game"):
# 		rpc_id(1, "start_game")
	# is_connected = true TODO

remote func _register_player(new_peer):
	players.push(new_peer)
	if get_tree().is_network_server():
		# I tell new player about all the existing people
		rset_id(new_peer, "players", players)
	# render_player_list() TODO
		# var right_team_count = 0
		# Send current players' info to new player
			# Send new player, old player's info
			# rpc_id(new_peer, "_register_player", old_peer, players[old_peer])
			# if old_peer != new_peer:
			# 	# We need to assign team later, so count current
			# 	if players[old_peer].is_right_team:
			# 		right_team_count += 1
				# if begun: TODO this should belong to lobby
				# 	rpc_id(old_peer, "_spawn_player", new_peer)
				# 	rpc_id(old_peer, "_begin_player_deferred", new_peer) # Spawning is deferred
		# var assign_right_team = right_team_count * 2 < players.size()
		# rpc("assign_team", new_peer, assign_right_team)
		# if not begun and players.size() == matchmaking.GAME_SIZE:
		# 	start_game()
		# if begun:
		# 	rpc_id(new_peer, "_pre_configure_game", my_info.level)
		# 	rpc_id(new_peer, "_post_configure_game")

sync func _unregister_player(peer):
	players.erase(peer)
	get_node("/root/Level/Players/%d" % peer).queue_free()

sync func _spawn_player(p):
	var hero = 0
	if players[p].has("hero"): # TODO: Rethink how we do this whole shenanigan
		hero = players[p].hero
	var player = load("res://scenes/heroes/" + str(hero) + ".tscn").instance()
	player.set_name(str(p))
	player.set_network_master(p)
	player.player_info = players[p]
	get_node("/root/Level/Players").call_deferred("add_child", player)

sync func _pre_configure_game(level):
	level = 2 # TODO: Remove this!!
	begun = true
	my_info.level = level # Remember the level for future player registration

	var self_peer_id = get_tree().get_network_unique_id()

	# Remove the interface so as to not fuck with things
	# But we still need the lobby alive to deal with networking!
	for element in get_node("/root/Lobby").get_children():
		element.queue_free()

	var world = load("res://scenes/levels/%d.tscn" % level).instance()
	get_node("/root").add_child(world)
	print("added level!")

	# Load all players (including self)
	for p in players:
		players[p].level = level
		_spawn_player(p)

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

