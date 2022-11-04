#tool
class_name XRPickableWire
extends XRToolsPickable

func get_class():
	return "XRPickableWire"

export var min_wirelength : float = 0.4
var EndBallA = null
var EndBallB = null

const colwire = Color(0.18, 0.13, 0.2, 1.0)
const colwiresolid = Color(0.18, 0.13, 0.5, 1.0)

func _ready() -> void:
	set_mode(RigidBody.MODE_KINEMATIC)
	reset_transform_on_pickup = false
	ranged_grab_method = RangedMethod.LERP
#	$SMeshWire/MeshWire.get_surface_material(0).albedo_color = colwire
#	$SMeshWire/MeshWire.scale.z = 0.1

var pullingspeed = 0.2
var bpulledsolid = false
var rotprism = Basis(Vector3(0,1,0), deg2rad(90))
func _physics_process(delta):
	if not is_picked_up():
		var mpt = (EndBallA.translation + EndBallB.translation)/2
		look_at_from_position(mpt, EndBallA.translation, transform.basis.y)
		var vec = EndBallB.translation - EndBallA.translation
		var veclen = vec.length()
		$CollisionShape.shape.extents.z = veclen
		var s = pullingspeed*delta
		var mid_radius = 0.01
		if not bpulledsolid and veclen - s >= min_wirelength:
			if not EndBallA.is_picked_up():
				EndBallA.translation += vec*(s/veclen)
			if not EndBallB.is_picked_up():
				EndBallB.translation -= vec*(s/veclen)
			mid_radius = 0.01*(min_wirelength/veclen)
		else:
			if not bpulledsolid:
				$SMeshWire/MeshWire.get_surface_material(0).albedo_color = colwiresolid
				bpulledsolid = true
			if not EndBallA.is_picked_up():
				EndBallA.translation = transform.origin - transform.basis.z*(min_wirelength/2)
			if not EndBallB.is_picked_up():
				EndBallB.translation = transform.origin + transform.basis.z*(min_wirelength/2)

			mid_radius = 0.01

		$SMeshWire.transform = Transform(Basis(), Vector3(0,0,-veclen/4))
		$SMeshWire/MeshWire.scale.y = veclen/2
#		$SMeshWire/MeshWire.mesh.top_radius = mid_radius
		$SMeshWire2.transform = Transform(Basis(), Vector3(0,0,veclen/4))
		$SMeshWire2/MeshWire2.scale.y = veclen/2
#		$SMeshWire2/MeshWire2.mesh.bottom_radius = mid_radius
	else:
		bpulledsolid = false
		var pluckposition = global_transform.origin
		var mpt1 = (EndBallA.translation + pluckposition)/2
		var mpt2 = (EndBallB.translation + pluckposition)/2
		$SMeshWire.look_at_from_position(mpt1, pluckposition, Vector3(0,1,0))
		$SMeshWire/MeshWire.scale.y = (pluckposition - EndBallA.translation).length()
		$SMeshWire2.look_at_from_position(mpt2, EndBallB.translation, Vector3(0,1,0))
		$SMeshWire2/MeshWire2.scale.y = (EndBallB.translation - pluckposition).length()
		#$MeshWire.mesh.top_radius = mid_radius
		#$MeshWire2.mesh.bottom_radius = mid_radius
		
func _on_PickableStrut_highlight_updated(pickable, enable):
	$SMeshWire/MeshWire.get_surface_material(0).albedo_color = Color.yellow if enable else (colwiresolid if bpulledsolid else colwire)
	
