extends Control

onready var networking = preload("res://scripts/networking.gd").new()

func _ready():
	add_child(networking)

	get_node("Server").connect("pressed", self, "_start_server")
	get_node("Client").connect("pressed", self, "_start_client")

func _start_server():
	networking.start_server(_get_port())
	_show_lobby()

func _start_client():
	var ip = get_node("IP").text
	networking.start_client(ip, _get_port())
	_show_lobby()

func _show_lobby():
	get_tree().change_scene("res://scenes/lobby.tscn")

func _get_port():
	var port = util.args.get_value("-port")
	return port

