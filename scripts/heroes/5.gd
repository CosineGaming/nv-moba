extends "res://scripts/player.gd"

onready var placement = preload("res://scripts/placement.gd").new(self, "res://scenes/heroes/5_portal.tscn")

var radius = 15
# The spaces make the bracket centered, rather than on of the dots
var first_crosshair = "   [..."
var second_crosshair = "...]   "

# --- Godot overrides ---

func _ready():
	placement.start_action = "hero_5_place_portal"
	placement.confirm_action = "hero_5_confirm_portal"
	placement.delete_action = "hero_5_remove_portal"
	placement.max_placed = 100

func _process(delta):
	if is_network_master():
		placement.place_input(radius)
		var is_second = placement.placed.size() % 2 != 0
		var crosshair = second_crosshair if is_second else first_crosshair
		get_node("MasterOnly/Crosshair").set_text(crosshair)

func _exit_tree():
	._exit_tree()
	if placement:
		placement.clear()

# --- Player overrides ---

# --- Own ---

