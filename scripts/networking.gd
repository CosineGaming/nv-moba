extends Node

onready var matchmaking = preload("res://scripts/matchmaking.gd").new()

remote var players = {}
var players_done = []
var global_server_ip = "nv.cosinegaming.com"
var matchmaker_tcp
var right_team_next = false

var level

signal info_updated

func _ready():
	add_child(matchmaking)

	get_tree().connect("network_peer_disconnected", self, "unregister_player")
	get_tree().connect("network_peer_connected", self, "register_player")
	get_tree().connect("connected_to_server", self, "_on_connect")

	connect("info_updated", self, "_check_info")

func start_client(ip="", port=0):
	if not ip:
		ip = util.args.get_value("-ip")
	ip = IP.resolve_hostname(ip)
	if not port:
		port = util.args.get_value("-port")
	var peer = NetworkedMultiplayerENet.new()
	print("Connecting to " + ip + ":" + str(port))
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	get_tree().change_scene("res://scenes/lobby.tscn")

remote func reconnect(port):
	# Reset previously known players
	players = {}
	start_client("", port)

func _connect_to_matchmaker(game_port):
	var matchmaker_peer = StreamPeerTCP.new()
	matchmaker_peer.connect_to_host("127.0.0.1", matchmaking.SERVER_TO_SERVER_PORT)
	var matchmaker_tcp = PacketPeerStream.new()
	matchmaker_tcp.set_stream_peer(matchmaker_peer)
	matchmaker_tcp.put_var(matchmaking.messages.ready_to_connect)
	matchmaker_tcp.put_var(game_port)

func start_server(port=0):
	if not port:
		port = util.args.get_value("-port")
	var peer = NetworkedMultiplayerENet.new()
	print("Starting server on port " + str(port))
	peer.create_server(port, matchmaking.GAME_SIZE)
	get_tree().set_network_peer(peer)
	# As soon as we're listening, let the matchmaker know
	_connect_to_matchmaker(port)
	register_player(get_tree().get_network_unique_id())
	if util.args.get_value("-silent"):
		set_info("spectating", true)
	get_tree().change_scene("res://scenes/lobby.tscn")

master func _start_game():
	rpc("_pre_configure_game", level)

func start_game():
	rpc_id(1, "_start_game")

func send_all_info(new_peer):
	for p in players:
		if p != new_peer:
			for key in players[p]:
				var val = players[p][key]
				# TODO: This broadcasts every connected peer,
				# which isn't really a problem but it's lazy
				set_info(key, val, p)

func _right_team_next():
	var right_team_count = 0
	for p in players:
		var player = players[p]
		if player.has("is_right_team") and player.is_right_team:
			right_team_count += 1
	return (right_team_count <= players.size() / 2)

remote func register_player(new_peer):
	if get_tree().is_network_server():
		# I tell new player about all the existing people
		send_all_info(new_peer)
		set_info("is_right_team", _right_team_next(), new_peer)

sync func unregister_player(peer):
	players.erase(peer)
	var p = util.get_player(peer)
	if p:
		p.queue_free()
	emit_signal("info_updated")

sync func _set_info(key, value, peer):
	if not players.has(peer):
		players[peer] = {}
	players[peer][key] = value
	emit_signal("info_updated")

master func set_info(key, value, peer=0):
	if not peer:
		peer = get_tree().get_network_unique_id()
	rpc("_set_info", str(key), value, peer)

# When connectivity is not yet guaranteed, the only one we know is always
# connected to everyone is the server. So in initial handshakes, it's better to
# tell the server what to tell everyone to do
func set_info_from_server(key, value, peer=0):
	if not peer:
		peer = get_tree().get_network_unique_id()
	rpc_id(1, "set_info", key, value, peer)

func _on_connect():
	register_player(get_tree().get_network_unique_id())
	emit_signal("info_updated")

func _check_info():
	# Check for "everyone is ready"
	# Only have 1 person check this, might as well be server
	if get_tree().is_network_server():
		var ready = true
		for p in players:
			if not players[p].has("spectating") or not players[p].spectating:
				if not players[p].has("ready") or not players[p].ready:
					ready = false
		if ready:
			start_game()

sync func _spawn_player(p):
	var hero = 0
	if players[p].has("hero"):
		hero = players[p].hero
	var player = load("res://scenes/heroes/" + str(hero) + ".tscn").instance()
	player.set_name(str(p))
	player.set_network_master(p)
	player.player_info = players[p]
	get_node("/root/Level/Players").add_child(player)

sync func _pre_configure_game(level):

	var self_peer_id = get_tree().get_network_unique_id()
	var self_begun = players[self_peer_id].begun

	if not self_begun:
		get_node("/root/Lobby").hide()

		var world = load("res://scenes/levels/%d.tscn" % level).instance()
		get_node("/root").add_child(world)

	# Load all players (including self)
	for p in players:
		if not players[p].spectating:
			var existing_player = util.get_player(p)
			if not self_begun or not existing_player:
				_spawn_player(p)

	# Why do we check first? Weird error. It's because set_info triggers a
	# start_game if everyone is ready
	# This causes a stack overflow if we call it from here repeatedly
	# So we only change it once, only start_game twice, and avoida segfault
	if not self_begun:
		print("setting my begun to true")
		set_info("begun", true)
	rpc_id(1, "_done_preconfiguring", self_peer_id)

sync func _done_preconfiguring(who):
	players_done.append(who)
	if players_done.size() == players.size():
		print("done")
		rpc("_post_configure_game")

sync func _post_configure_game():
	# Begin all players (including self)
	for p in players:
		if not players[p].spectating:
			_begin_player(p)

func _begin_player(peer):
	util.get_player(peer).begin()

sync func reset_state():
	players_done = []
	get_node("/root/Level").queue_free()

