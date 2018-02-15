extends Label

var camera
var pos

func _ready():
	pos = get_node("../NamePosition")

func _process(delta):
	if not camera:
		# This needs to happen here because players are added later
		camera = get_node("/root/Level/Players/%d" % get_tree().get_network_unique_id()).get_node("TPCamera/Camera")
	var size = get_size()
	var offset = Vector2(size.x/2, size.y) # Origin at bottom
	var pos3d = pos.get_global_transform().origin
	set_position(camera.unproject_position(pos3d) - offset)

