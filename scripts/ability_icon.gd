extends Control

onready var hero = get_node("../..")
onready var bar = get_node("Bar")
onready var available = get_node("Available")
export var cost = 1
export var ability_name = "Ability"
export var display_progress = true
export var action = ""
# This is intended to be public
var disabled = false

func _ready():
	get_node("Name").text = ability_name
	var description
	if action:
		var primary = InputMap.get_action_list(action)[0]
		if primary is InputEventMouseButton:
			if primary.button_index == BUTTON_LEFT:
				description = "Click"
			elif primary.button_index == BUTTON_RIGHT:
				description = "Right Click"
			else:
				description = "Scroll Click"
		else:
			description = primary.as_text()
	else:
		description = ""
	get_node("Button").text = description

func is_pressed():
	return Input.is_action_pressed(action)

func _process(delta):
	if action and Input.is_action_pressed(action):
		available.rect_position = Vector2(-25, -25) # Centered / not offset
	else:
		available.rect_position = Vector2(-30, -30)
	if disabled:
		available.hide()
		bar.value = 0
	else:
		if display_progress:
			if cost == 0:
				bar.value = 100 if hero.switch_charge > 0 else 0
			else:
				bar.value = 100 * hero.switch_charge / cost
		if hero.switch_charge > cost:
			available.show()
		else:
			available.hide()
