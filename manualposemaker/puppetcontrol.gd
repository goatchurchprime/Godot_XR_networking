extends XRToolsPickable

signal pointer_event(event)

const col1 = Color("f98ddd7c")
const col2 = Color("0edf007c")

var controllerpickedby = null
@export var bonecontrolname = "hand .L"
@onready var GeonPoseMaker = get_node("../..")

var bonenode = null
var bonenodenexthinge = null
var Dtwave = 0
var qhingeorg = null

# see if we can remove the trj and make it apply onto the geonobjects.transform itself
# then we can move it around after construction

func on_pointer_event(e : XRToolsPointerEvent) -> void:
	#if e.event_type == XRToolsPointerEvent.Type.ENTERED:
	#	$MeshInstance3D.get_surface_override_material(0).albedo_color = col2
	#if e.event_type == XRToolsPointerEvent.Type.EXITED:
	#	$MeshInstance3D.get_surface_override_material(0).albedo_color = col1
	pass

func _ready():
	connect("pointer_event", on_pointer_event)

var currentlyheld = false
var controllerlocbasis = null
var controllerbasisyrot = null
var bonenodeorgpos = null
var controllerlocorgpos = null

func _process(delta):
	if currentlyheld:
		bonenode.global_transform.basis = transform.basis * controllerlocbasis
		bonenode.global_transform.origin = bonenodeorgpos + controllerbasisyrot*(transform.origin - controllerlocorgpos)
		
		if bonenodenexthinge != null:
			var Dswinghingebytime = true
			if not Dswinghingebytime:
				bonenodenexthinge.global_transform.basis = bonenode.global_transform.basis * qhingeorg
			else:
				Dtwave += delta
				var hingevec = bonenode.global_transform.basis*bonenode.jointhingevectortop
				var Dangsin = sin(Dtwave*3)*0.2
				var Dqhingwave = Quaternion(hingevec.x*Dangsin, hingevec.y*Dangsin, hingevec.z*Dangsin, sqrt(1 - Dangsin*Dangsin))
				bonenodenexthinge.global_transform.basis = Basis(Dqhingwave) * bonenode.global_transform.basis * qhingeorg
			var jointpos = bonenode.global_transform.origin + bonenode.global_transform.basis*Vector3(0,bonenode.rodlength/2,0) # derivebointjointcentre
			bonenodenexthinge.global_transform.origin = jointpos - bonenodenexthinge.global_transform.basis*Vector3(0,-bonenode.rodlength/2,0)
			
			var Dhingeaxis = bonenode.global_transform.basis*bonenode.jointhingevectortop
			var DhingeaxisN = bonenodenexthinge.global_transform.basis*bonenodenexthinge.jointhingevectorbottom
			if (Dhingeaxis - DhingeaxisN).length() > 0.01:
				print("Dhingeaxis not equal ", Dhingeaxis, DhingeaxisN)

			
func _on_picked_up(pickable):
	controllerpickedby = pickable.by_controller
	if not controllerpickedby.is_button_pressed("trigger_click"):
		if bonenode == null or bonenode.skelbone["bonename"] != bonecontrolname:
			bonenode = get_node("../..").findbonenodefromname(bonecontrolname)
			if bonenode.jointhingevectortop != null:
				bonenodenexthinge = bonenode.jointobjecttop
				print("next hinge detected ", bonenodenexthinge)
			
	if bonenode != null:
		controllerlocbasis = transform.basis.inverse()*bonenode.global_transform.basis
		controllerlocorgpos = transform.origin
		bonenodeorgpos = bonenode.global_transform.origin

		var xr_cameraz = get_node("../..").xr_camera.basis.z
		var skelz = bonenode.skelbone["skel"].global_transform.basis.z
		var locangy = Vector2(xr_cameraz.x, xr_cameraz.z).angle_to(Vector2(skelz.x, skelz.z))
		print("locangy ", rad_to_deg(locangy))
		controllerbasisyrot = Basis(Vector3(0,1,0), 0-locangy)
		currentlyheld = true

		if bonenodenexthinge != null:
			assert (bonenode.jointobjecttop == bonenodenexthinge)
			assert (bonenode == bonenodenexthinge.jointobjectbottom)
			var q1 = bonenode.global_transform.basis
			var h1 = bonenode.jointhingevectortop
			var v1 = Vector3(0,1,0)
			var e1 = (v1 - h1.dot(v1)*h1).normalized()
			var q2 = bonenodenexthinge.global_transform.basis
			var h2 = bonenodenexthinge.jointhingevectorbottom
			var v2 = Vector3(0,-1,0)
			var e2 = (v2 - h2.dot(v2)*h2).normalized()
			var hingevec1 = q1*h1
			var hingevec2 = q2*h2
			qhingeorg = q1.inverse()*q2
			#func forceonhingeifnecessary(q1, q2):
			# var qrot = Qrotationtoalign(hingevec2, hingevec1)
			# newq2 = qrot*q2

			
		GeonPoseMaker.pickupgeon(null, bonenode, bonenodenexthinge)

func _on_dropped(pickable):
	if currentlyheld and bonenode:
		GeonPoseMaker.dropgeon(null, bonenode, bonenodenexthinge)
		controllerpickedby = null
		currentlyheld = false

func _on_highlight_updated(pickable, enable):
	if enable:
		$MeshInstance3D.get_surface_override_material(0).albedo_color = col2
	else:
		$MeshInstance3D.get_surface_override_material(0).albedo_color = col1
