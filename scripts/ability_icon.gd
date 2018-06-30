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
	_render_input()

func is_pressed():
	return Input.is_action_pressed(action)

func _input(e):
	if e.is_action(action):
		# We just used e to do our action
		# Detect which one we used
		if action:
			var possible = InputMap.get_action_list(action)
			if possible:
				for i in range(possible.size()):
					# We use as_text == instead of shortcut_match because
					# shortcut_match doesn't work with controllers
					if possible[i].as_text() == e.as_text():
						util.input_index = i
	_render_input()

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
				bar.value = 100
			else:
				bar.value = 100 * hero.charge / cost
		if hero.charge >= cost:
			available.show()
		else:
			available.hide()

func _render_input():
	var description
	if action:
		var actions = InputMap.get_action_list(action)
		if actions:
			var used = actions[util.input_index]
			if used is InputEventMouseButton:
				if used.button_index == BUTTON_LEFT:
					description = "Click"
				elif used.button_index == BUTTON_RIGHT:
					description = "Right Click"
				else:
					description = "Scroll Click"
			elif used is InputEventJoypadButton:
				description = Input.get_joy_button_string(used.button_index)
			else:
				description = used.as_text()
		else:
			description = action # Just text
	else:
		description = ""
	get_node("Button").text = description

