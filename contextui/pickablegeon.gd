extends XRToolsPickable

signal pointer_event(event)

func on_pointer_event(event : XRToolsPointerEvent) -> void:
	pass # print("Geon ", event)

func _ready():
	$CollisionShape3D.shape = $CSGMesh.mesh.create_convex_shape()
	connect("pointer_event", on_pointer_event)
	
func contextmenucommands():
	return [ "delete", "extend", "shrink", "fat1", "fat2", "split" ]

func executecontextmenucommand(cmc):
	if cmc == "extend":
		$CSGMesh.mesh.height *= 1.5
	if cmc == "shrink":
		$CSGMesh.mesh.height /= 1.5
	$CollisionShape3D.shape = $CSGMesh.mesh.create_convex_shape()

	print(name, "-- contextmenucommand ", cmc)
