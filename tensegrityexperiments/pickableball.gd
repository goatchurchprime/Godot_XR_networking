tool
class_name XRPickableBall
extends XRToolsPickable

func get_class():
	return "XRPickableBall"

func _ready() -> void:
	set_mode(RigidBody.MODE_KINEMATIC)
	reset_transform_on_pickup = false
	ranged_grab_method = RangedMethod.LERP
	$MeshBall.get_surface_material(0).albedo_color = Color.darkcyan

func _on_Ball_highlight_updated(pickable, enable):
	$MeshBall.get_surface_material(0).albedo_color = Color.yellow if enable else Color.darkcyan
