extends Control

func _ready():
	get_node("Server").connect("pressed", self, "_start_server")
	get_node("Client").connect("pressed", self, "_start_client")
	get_node("Back").connect("pressed", get_tree(), "change_scene", ["res://scenes/menu.tscn"])

func _start_server():
	# Custom Game can assume we're playing as well
	networking.start_server()

func _start_client():
	var ip = get_node("IP").text
	networking.start_client(ip)
