tool
class_name XRPickableStrut
extends XRToolsPickable


export var strut_length : float = 0.6
var EndBallA = null
var EndBallB = null

# Called when this handle is added to the scene
func _ready() -> void:
	set_mode(RigidBody.MODE_KINEMATIC)
	reset_transform_on_pickup = false
	ranged_grab_method = RangedMethod.LERP
	$MeshStrut.get_surface_material(0).albedo_color = Color.darkgreen
	$MeshStrut.scale.z = strut_length
	$CollisionShape.shape.extents.z = strut_length/2

func _physics_process(delta):
	if not is_picked_up():
		var mpt = (EndBallA.translation + EndBallB.translation)/2
		look_at_from_position(mpt, EndBallA.translation, transform.basis.y)
	if not EndBallA.is_picked_up():
		EndBallA.translation = transform.origin - transform.basis.z*(strut_length/2)
	if not EndBallB.is_picked_up():
		EndBallB.translation = transform.origin + transform.basis.z*(strut_length/2)

func _on_PickableStrut_highlight_updated(pickable, enable):
	$MeshStrut.get_surface_material(0).albedo_color = Color.yellow if enable else Color.darkgreen
	