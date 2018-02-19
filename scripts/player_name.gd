extends Label

var camera
var pos

func _ready():
	pos = get_node("../NamePosition")

func _process(delta):
	# This needs to happen here because players are added later
	# Plus, the camera changes when a player switches hero
	camera = util.get_master_player().get_node("TPCamera/Camera")
	var pos3d = pos.get_global_transform().origin
	if camera.is_position_behind(pos3d):
		hide()
	else:
		show()
		var size = get_size()
		var offset = Vector2(size.x/2, size.y) # Origin at bottom
		set_position(camera.unproject_position(pos3d) - offset)

