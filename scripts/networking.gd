extends Node

func connect_global_server():
	ip = global_server_ip
	_client_init()

slave func client_init(given_port=null):
	collect_info()
	var peer = NetworkedMultiplayerENet.new()
	if not ip:
		ip = get_node("CustomGame/IP").get_text()
	ip = IP.resolve_hostname(ip)
	if given_port:
		port = given_port
	print("Connecting to " + ip + ":" + str(port))
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	get_node("CustomGame/Client").set_text("Clienting!")

func singleplayer_init():
	collect_info()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, 1)
	get_tree().set_network_peer(peer)
	player_info[1] = my_info
	start_game()

func server_init():
	collect_info()
	var peer = NetworkedMultiplayerENet.new()
	print("Starting server on port " + str(port))
	peer.create_server(port, matchmaking.GAME_SIZE)
	get_tree().set_network_peer(peer)
	# As soon as we're listening, let the matchmaker know
	var matchmaker_peer = StreamPeerTCP.new()
	matchmaker_peer.connect_to_host("127.0.0.1", matchmaking.SERVER_TO_SERVER_PORT)
	matchmaker_tcp = PacketPeerStream.new()
	matchmaker_tcp.set_stream_peer(matchmaker_peer)
	# matchmaker_tcp.put_packet([matchmaking.messages.ready_to_connect, port])
	matchmaker_tcp.put_var(matchmaking.messages.ready_to_connect)
	matchmaker_tcp.put_var(port)
	is_connected = true
	get_node("CustomGame/Server").set_text("Serving!")
	get_node("JoinedGameLobby").show()
	if server_playing:
		player_info[1] = my_info
	if "start_game" in my_info and my_info.start_game:
		start_game()

func matchmaker_init():
	matchmaking.run_matchmaker()

func player_disconnected(id):
	if get_tree().is_network_server():
		rpc("unregister_player", id)
	call_deferred("render_player_list")

func player_connected():
	rpc("register_player", get_tree().get_network_unique_id(), my_info)
	if "start_game" in my_info and my_info.start_game:
		rpc_id(1, "start_game")
	get_node("JoinedGameLobby").show()
	is_connected = true

remote func register_player(new_peer, info):
	player_info[new_peer] = info
	render_player_list()
	if (get_tree().is_network_server()):
		var right_team_count = 0
		# Send current players' info to new player
		for old_peer in player_info:
			# Send new player, old player's info
			rpc_id(new_peer, "register_player", old_peer, player_info[old_peer])
			if old_peer != new_peer:
				# We need to assign team later, so count current
				if player_info[old_peer].is_right_team:
					right_team_count += 1
				# You'd think this part could be met with a simple `rpc(`, but actually it can't
				# My best guess is this is because we haven't registered the names yet, but I'm not sure (TODO)
				if old_peer != 1:
					# Send old player, new player's info (not us, no infinite loop)
					rpc_id(old_peer, "register_player", new_peer, info)
				if begun:
					rpc_id(old_peer, "spawn_player", new_peer)
					rpc_id(old_peer, "begin_player_deferred", new_peer) # Spawning is deferred
		if not server_playing:
			# We didn't catch this in player_info
			rpc_id(1, "spawn_player", new_peer)
			rpc_id(1, "begin_player_deferred", new_peer) # Spawning is deferred
		var assign_right_team = right_team_count * 2 < player_info.size()
		rpc("assign_team", new_peer, assign_right_team)
		if not begun and player_info.size() == matchmaking.GAME_SIZE:
			start_game()
		if begun:
			rpc_id(new_peer, "pre_configure_game", my_info.level)
			rpc_id(new_peer, "post_configure_game")

sync func unregister_player(peer):
	player_info.erase(peer)
	get_node("/root/Level/Players/%d" % peer).queue_free()

sync func assign_team(peer, is_right_team):
	player_info[peer].is_right_team = is_right_team
	if peer == get_tree().get_network_unique_id():
		if is_right_team:
			get_node("PlayerSettings/Team").set_text("Right Team")
		else:
			get_node("PlayerSettings/Team").set_text("Left Team")
	render_player_list()

sync func start_game():
	my_info.level = get_node("CustomGame/LevelSelect").get_selected_id()
	rpc("pre_configure_game", my_info.level)

sync func done_preconfiguring(who):
	players_done.append(who)
	if players_done.size() == player_info.size():
		# We call deferred in case singleplayer has placing the player in queue still
		call_deferred("rpc", "post_configure_game")

sync func spawn_player(p):
	var hero = player_info[p].hero
	var player = load("res://scenes/heroes/" + str(hero) + ".tscn").instance()
	player.set_name(str(p))
	player.set_network_master(p)
	player.player_info = player_info[p]
	get_node("/root/Level/Players").call_deferred("add_child", player)

sync func pre_configure_game(level):
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
	for p in player_info:
		player_info[p].level = level
		spawn_player(p)

	rpc_id(1, "done_preconfiguring", self_peer_id)

func begin_player(peer):
	get_node("/root/Level/Players/%d" % peer).begin()

remote func begin_player_deferred(peer):
	call_deferred("begin_player", peer)

sync func reset_state():
	players_done = []
	get_node("/root/Level").queue_free()

sync func post_configure_game():
	# Begin all players (including self)
	for p in player_info:
		begin_player_deferred(p)

