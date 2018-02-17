extends StaticBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func set_color(color):
	var mat = SpatialMaterial.new()
	mat.albedo_color = color
	get_node("MeshInstance").set_surface_material(0, mat)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
