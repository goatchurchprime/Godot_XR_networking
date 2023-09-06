#tool
class_name XRPickableWire
extends XRToolsPickable


@export var min_wirelength : float = 0.4
var EndBallA = null
var EndBallB = null

const colwire = Color(0.18, 0.13, 0.2, 1.0)
const colwiresolid = Color(0.18, 0.13, 0.5, 1.0)
const colwiresolidslack = Color(0.38, 0.13, 0.2, 1.0)

var bpulledsolid = false
var bslack = false
var rotprism = Basis(Vector3(0,1,0), deg_to_rad(90))

func _ready() -> void:
	set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	ranged_grab_method = RangedMethod.LERP


func recpulledwire(ballFrameN, ds):
	var mpt = (EndBallA.position + EndBallB.position)/2
	look_at_from_position(mpt, EndBallA.position, transform.basis.y)
	var vec = EndBallB.position - EndBallA.position
	var veclen = vec.length()
	$CollisionShape3D.shape.size.z = veclen

	if not bpulledsolid and veclen - ds >= min_wirelength:
		var evec = vec*(ds/min_wirelength)
		EndBallA.addsumpt(EndBallA.position + evec, ballFrameN)
		EndBallB.addsumpt(EndBallB.position - evec, ballFrameN)
	else:
		bpulledsolid = true
		bslack = (veclen < min_wirelength + ds)
		$SMeshWire/MeshWire.get_active_material(0).albedo_color = colwiresolidslack if bslack else colwiresolid
		if not bslack:
			EndBallA.addsumpt(transform.origin - transform.basis.z*(min_wirelength/2), ballFrameN)
			EndBallB.addsumpt(transform.origin + transform.basis.z*(min_wirelength/2), ballFrameN)
	$SMeshWire.transform = Transform3D(Basis(), Vector3(0,0,0))
	$SMeshWire/MeshWire.scale.y = veclen
	$SMeshWire2.visible = false


func _physics_process(delta):
	if is_picked_up():
		bpulledsolid = false
		$SMeshWire/MeshWire.get_surface_override_material(0).albedo_color = colwire
		var pluckposition = global_transform.origin
		var mpt1 = (EndBallA.position + pluckposition)/2
		var mpt2 = (EndBallB.position + pluckposition)/2
		$SMeshWire.look_at_from_position(mpt1, pluckposition, Vector3(0,1,0))
		$SMeshWire/MeshWire.scale.y = (pluckposition - EndBallA.position).length()
		$SMeshWire2.look_at_from_position(mpt2, EndBallB.position, Vector3(0,1,0))
		$SMeshWire2/MeshWire2.scale.y = (EndBallB.position - pluckposition).length()
		$SMeshWire2.visible = true
		
func _on_PickableStrut_highlight_updated(pickable, enable):
	var col = colwire
	if enable:
		col = Color.YELLOW
	elif bpulledsolid:
		col = colwiresolidslack if bslack else colwiresolid
	$SMeshWire/MeshWire.get_surface_override_material(0).albedo_color = col
