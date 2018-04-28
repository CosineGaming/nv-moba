extends StaticBody

var maker_node
var material
var destroy_cost = 20

func _ready():
	get_node("CollisionShape").disabled = true

func init(maker):
	maker_node = maker

	material = get_node("MeshInstance").get_surface_material(0)
	if not material:
		material = SpatialMaterial.new()
		get_node("MeshInstance").set_surface_material(0, material)
	material.flags_transparent = true
	material.albedo_color.a = 0.5

func place():
	# Originally, the ghost is disabled to avoid weird physics
	get_node("CollisionShape").disabled = false
	material.flags_transparent = false

func destroy():
	queue_free()
	return destroy_cost

func make_last():
	material.flags_transparent = true
	material.albedo_color.a = 0.9

func out_of_range():
	material.albedo_color.a = 0.2

func within_range():
	material.albedo_color.a = 0.5

