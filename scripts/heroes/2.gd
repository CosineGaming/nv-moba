extends "res://scripts/player.gd"

#func _ready():
#	get_node("Area").set_gravity_distance_scale(10)

var is_repelling = false
var repel_hud

func _ready():
	print("nutty")
	if is_network_master():
		print("netty")
		repel_hud = Label.new()
		repel_hud.set_name("RepellingHUD")
		repel_hud.set_text("\\/")
		repel_hud.set_position(Vector2(0, -20))
		repel_hud.set_visible_characters(2)
		repel_hud.set_align(Label.VALIGN_CENTER)
		get_node("Centered").add_child(repel_hud)

func _process(delta):
	if is_network_master():
		if Input.is_action_just_pressed("hero_2_switch_gravity"):
			rpc("switch_gravity")
			is_repelling = !is_repelling
			if is_repelling:
				repel_hud.set_text("/\\")
			else:
				repel_hud.set_text("\\/")

sync func switch_gravity():
	var area = get_node("Area")
	area.set_gravity(-area.get_gravity())

