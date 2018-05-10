extends Control

onready var networking = preload("res://scripts/networking.gd").new()

func _ready():
	add_child(networking)

	get_node("Server").connect("pressed", networking, server_init)
	get_node("Client").connect("pressed", networking, client_init)
