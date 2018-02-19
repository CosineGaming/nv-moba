extends "res://scripts/player.gd"

onready var placement = preload("res://scripts/placement.gd").new(self, "res://scenes/heroes/1_wall.tscn")

# --- Godot overrides ---

func _ready():
	placement.start_action = "hero_1_place_wall"
	placement.confirm_action = "hero_1_confirm_wall"
	placement.delete_action = "hero_1_remove_wall"
	placement.max_placed = 100

func _process(delta):
	if is_network_master():
		placement.place_input()

func _exit_tree():
	._exit_tree()
	if placement:
		placement.clear()

# --- Player overrides ---

func spawn():
	.spawn()
	if placement:
		placement.clear()

# --- Own ---

