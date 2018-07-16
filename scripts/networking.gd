extends Node

# Public variables
# ================

onready var matchmaking = preload("res://scripts/matchmaking.gd").new()

remote var players = {}
var global_server_ip = "nv.cosinegaming.com"
var matchmaker_tcp

var level
var port

signal info_updated

# Public methods
# ==============

func start_client(ip="", _port=0):
	if not ip:
		ip = util.args.get_value("-ip")
	ip = IP.resolve_hostname(ip)
	if not port:
		port = util.args.get_value("-port")
	if _port:
		port = _port
	var peer = NetworkedMultiplayerENet.new()
	util.log("Connecting to " + ip + ":" + str(port))
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	get_tree().change_scene("res://scenes/lobby.tscn")

remote func reconnect(ip, _port):
	# Reset previously known players
	players = {}
	port = _port
	start_client(ip, _port)

func start_server(_port=0):
	if not port:
		port = util.args.get_value("-port")
	if _port:
		port = _port
	var peer = NetworkedMultiplayerENet.new()
	util.log("Starting server on port " + str(port))
	peer.create_server(port, matchmaking.GAME_SIZE)
	get_tree().set_network_peer(peer)
	# As soon as we're listening, let the matchmaker know
	_connect_to_matchmaker(port)
	_register_player(get_tree().get_network_unique_id())
	if util.args.get_value("-silent"):
		set_info("spectating", true)
	get_tree().change_scene("res://scenes/lobby.tscn")

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

func start_game():
	rpc_id(1, "_start_game")

sync func reset_state():
	for p in players:
		players[p].begun = false
		# TODO: Do I in fact want to unready everyone automatically?
		players[p].ready = false
	# TODO: Is this not very kosher?
	util.get_master_player().toggle_mouse_capture()
	get_node("/root/Lobby").show()
	get_node("/root/Level").queue_free()


# Private methods
# ===============

func _ready():
	add_child(matchmaking)

	get_tree().connect("network_peer_disconnected", self, "_unregister_player")
	get_tree().connect("network_peer_connected", self, "_register_player")
	get_tree().connect("connected_to_server", self, "_on_connect")

	connect("info_updated", self, "_check_info")

remote func _register_player(new_peer):
	util.log("Player " + str(new_peer) + " connected.")
	if get_tree().is_network_server():
		# I tell new player about all the existing people
		_send_all_info(new_peer)
		set_info("is_right_team", _right_team_next(), new_peer)

sync func _unregister_player(peer):
	util.log("Player " + str(peer) + " disconnected.")
	players.erase(peer)
	var p = util.get_player(peer)
	if p:
		p.queue_free()
	emit_signal("info_updated")

func _connect_to_matchmaker(game_port):
	var matchmaker_peer = StreamPeerTCP.new()
	matchmaker_peer.connect_to_host("127.0.0.1", matchmaking.SERVER_TO_SERVER_PORT)
	var matchmaker_tcp = PacketPeerStream.new()
	matchmaker_tcp.set_stream_peer(matchmaker_peer)
	matchmaker_tcp.put_var(matchmaking.messages.ready_to_connect)
	matchmaker_tcp.put_var(game_port)

master func _start_game():
	rpc("_pre_configure_game", level)

func _send_all_info(new_peer):
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

sync func _set_info(key, value, peer):
	if not players.has(peer):
		players[peer] = {}
	players[peer][key] = value
	emit_signal("info_updated")

func _on_connect():
	_register_player(get_tree().get_network_unique_id())
	emit_signal("info_updated")

func _check_info():
	# Check for "everyone is ready"
	# Only have 1 person check this, might as well be server
	if get_tree().is_network_server():
		var ready = true
		var all_done = true
		for p in players:
			if not players[p].has("spectating") or not players[p].spectating:
				if not players[p].has("ready") or not players[p].ready:
					ready = false
				if not players[p].has("begun") or not players[p].begun:
					all_done = false
		if all_done:
			rpc("_post_configure_game")
		elif ready:
			# If we're all done, then we don't need to even check a start_game
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

func _begin_player(p):
	var player = util.get_player(p)
	player.begin()

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
	for p in players:
		if not players[p].spectating:
			# Begin requires all players
			_begin_player(p)

	# Why do we check first? Weird error. It's because set_info triggers a
	# start_game if everyone is ready
	# This causes a stack overflow if we call it from here repeatedly
	# So we only change it once, only start_game twice, and avoida segfault
	if not self_begun:
		set_info("begun", true)

sync func _post_configure_game():
	# Begin all players (including self)
	# TODO: What do? Maybe, unpause game?
	pass

