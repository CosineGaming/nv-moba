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
var _free_color = Color(0.082886, 0.615445, 0.757812) # Light blue

func _ready():
	get_node("Name").text = ability_name
	if cost == 0:
		available.color = _free_color
	var description
	if action:
		var actions = InputMap.get_action_list(action)
		if actions:
			var primary = actions[0]
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
			description = action # Just text
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
				bar.value = 100 if hero.charge > 0 else 0
			else:
				bar.value = 100 * hero.charge / cost
		if hero.charge > cost:
			available.show()
		else:
			available.hide()
