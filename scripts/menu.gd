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
	print("still refactoring matchmaker")

func _custom_game():
	get_tree().change_scene("res://scenes/custom_game.tscn")

func _singleplayer():
	print("still refactoring singleplayer")

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
	# if o.get_value("-silent"):
	# 	server_playing = false
	# if o.get_value("-hero"):
	# 	var hero = o.get_value("-hero")
	# 	_option_sel("PlayerSettings/HeroSelect", hero)
	# 	# For some reason, calling _option_sel doesn't trigger the actual selection
	# 	select_hero(get_node("PlayerSettings/HeroSelect").get_selected_id())
	# if o.get_value("-level"):
	# 	_option_sel("CustomGame/LevelSelect", o.get_value("-level"))
	# if o.get_value("-port"):
	# 	port = o.get_value("-port")
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
	if o.get_value("-start-game"):
		networking.call_deferred("start_game")
	# if o.get_value("-singleplayer"):
	# 	networking.call_deferred("start_singleplayer")
	if o.get_value('-h'):
		o.print_help()
		quit()

