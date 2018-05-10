extends "res://scripts/args.gd"

func _ready():
	randomize()
	_parse_args()
	_gui_setup()

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

func _set_up_options():
	var opts = Options.new()
	opts.set_banner(('A non-violent MOBA inspired by Overwatch and Zineth'))
	opts.add('-singleplayer', false, 'Whether to run singeplayer, starting immediately')
	opts.add('-server', false, 'Whether to run as server')
	opts.add('-matchmaker', false, 'Whether to be the sole matchmaker')
	opts.add('-client', false, 'Immediately connect as client')
	opts.add('-silent', false, 'If the server is not playing, merely serving')
	opts.add('-port', 54672, 'The port to run a server on or connect to')
	opts.add('-hero', 'r', 'Your choice of hero (index)')
	opts.add('-level', 'r', 'Your choice of level (index) - server only!')
	opts.add('-start-game', false, 'Join as a client and immediately start the game')
	opts.add('-ai', true, 'Run this client as AI')
	opts.add('-no-record', true, "Don't record this play for AI later")
	opts.add('-h', false, "Print help")
	return opts

func _option_sel(button_name, option):
	var button = get_node(button_name)
	if option == "r":
		option = randi() % button.get_item_count()
	else:
		option = int(option)
	button.select(option)

func _parse_args():
	var o = _set_up_options()
	o.parse()

	# if o.get_value("-silent"):
	# 	server_playing = false
	# if o.get_value("-hero"):
	# 	var hero = o.get_value("-hero")
	# 	_option_sel("PlayerSettings/HeroSelect", hero)
	# 	# For some reason, calling _option_sel doesn't trigger the actual selection
	# 	select_hero(get_node("PlayerSettings/HeroSelect").get_selected_id())
	# if o.get_value("-level"):
	# 	_option_sel("CustomGame/LevelSelect", o.get_value("-level"))
	# if o.get_value("-server"):
	# 	call_deferred("_server_init")
	# if o.get_value("-matchmaker"):
	# 	call_deferred("_matchmaker_init")
	# if o.get_value("-client"):
	# 	call_deferred("_client_init")
	# if o.get_value("-port"):
	# 	port = o.get_value("-port")
	# if o.get_value("-start-game"):
	# 	my_info.start_game = true
	# if o.get_value("-singleplayer"):
	# 	call_deferred("_singleplayer_init")
	# if o.get_value("-ai"):
	# 	my_info.is_ai = true
	# if not o.get_value("-no-record") and not o.get_value("-ai"):
	# 	my_info.record = true
	# if o.get_value('-h'):
	# 	o.print_help()
	# 	quit()

