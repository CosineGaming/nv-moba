extends Control

func _ready():
	randomize()
	_gui_setup()
	_arg_actions()

# GUI

func _gui_setup():
	get_node("Center/Play").connect("pressed", self, "_find_game")
	get_node("Center/CustomGame").connect("pressed", self, "_custom_game")
	get_node("Center/Singleplayer").connect("pressed", self, "_singleplayer")

func _find_game():
	var ip = networking.global_server_ip
	var port = networking.matchmaking.MATCHMAKING_PORT
	networking.start_client(ip, port)

func _custom_game():
	get_tree().change_scene("res://scenes/custom_game.tscn")

func _singleplayer():
	networking.start_server()
	get_tree().change_scene("res://scenes/singleplayer_lobby.tscn")

# Command line

func _option_sel(button_name, option):
	var button = get_node(button_name)
	if option == "r":
		option = randi() % button.get_item_count()
	else:
		option = int(option)
	button.select(option)

func _arg_actions():
	var o = util.args
	# if o.get_value("-ai"):
	# 	my_info.is_ai = true
	# if not o.get_value("-no-record") and not o.get_value("-ai"):
	# 	my_info.record = true
	if o.get_value("-server"):
		networking.start_server()
		get_tree().change_scene("res://scenes/lobby.tscn")
	# if o.get_value("-matchmaker"):
	# 	call_deferred("_matchmaker_init")
	if o.get_value("-client"):
		networking.start_client()
		get_tree().change_scene("res://scenes/lobby.tscn")
	if o.get_value("-singleplayer"):
		_singleplayer()
	if o.get_value('-h'):
		o.print_help()
		quit()

