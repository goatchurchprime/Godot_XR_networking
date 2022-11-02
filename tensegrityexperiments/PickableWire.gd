#tool
class_name XRPickableWire
extends XRToolsPickable

export var min_wirelength : float = 0.4
var EndBallA = null
var EndBallB = null

const colwire = Color(0.18, 0.13, 0.2, 1.0)
# Called when this handle is added to the scene
func _ready() -> void:
	set_mode(RigidBody.MODE_KINEMATIC)
	reset_transform_on_pickup = false
	ranged_grab_method = RangedMethod.LERP
	$MeshWire.get_surface_material(0).albedo_color = colwire
	$MeshWire.scale.z = 0.1

var pullingspeed = 0.2
func _physics_process(delta):
	if not is_picked_up():
		var mpt = (EndBallA.translation + EndBallB.translation)/2
		look_at_from_position(mpt, EndBallA.translation, transform.basis.y)
		var vec = EndBallB.translation - EndBallA.translation
		var veclen = vec.length()
		$CollisionShape.shape.extents.z = veclen
		var s = pullingspeed*delta
		var mid_radius = 0.02
		if veclen - s >= min_wirelength:
			EndBallA.translation += vec*(s/veclen)
			EndBallB.translation -= vec*(s/veclen)
			mid_radius = 0.01*(min_wirelength/veclen)

		$MeshWire.scale.y = veclen/2
		$MeshWire.translation = Vector3(0,0,-veclen/4)
		$MeshWire.mesh.top_radius = mid_radius
		$MeshWire2.translation = Vector3(0,0,veclen/4)
		$MeshWire2.scale.y = veclen/2
		$MeshWire2.mesh.bottom_radius = mid_radius

	else:
		pass
		
func _on_PickableStrut_highlight_updated(pickable, enable):
	$MeshWire.get_surface_material(0).albedo_color = Color.yellow if enable else colwire
	
