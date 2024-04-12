extends XRToolsPickable

signal pointer_event(event)

const col1 = Color("f98ddd7c")
const col2 = Color("0edf007c")

var controllerpickedby = null
@export var bonecontrolname : String = "hand .L"
@export var hinganglemin : float = 50
@export var hinganglemax : float = 190

@onready var GeonPoseMaker = get_node("../..")

var bonenode = null
var bonenodenexthinge = null
var Dtwave = 0
var qhingeorg = null
var qhingeorgangle = 0.0


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
				var controllerfloat = controllerpickedby.get_float("trigger") if controllerpickedby else 0.5
				#controllerfloat = (sin(Dtwave*2)+1)/2
				var controllerhingeangle = lerp(hinganglemin, hinganglemax, controllerfloat)
				controllerhingeangle = lerp(hinganglemin, hinganglemax, controllerfloat)
				var hingeaddangrad = deg_to_rad((sin(Dtwave*3)+1)*45)
				hingeaddangrad = deg_to_rad(qhingeorgangle - controllerhingeangle)

				#Dangsin = sin(deg_to_rad((180 + (controllerhingeangle - qhingeorgangle))/2))
				var qhingeaddeaddI = hingevec*sin(hingeaddangrad/2)
				var qhingeaddeadd = Quaternion(qhingeaddeaddI.x, qhingeaddeaddI.y, qhingeaddeaddI.z, cos(hingeaddangrad/2))
				bonenodenexthinge.global_transform.basis = Basis(qhingeaddeadd) * bonenode.global_transform.basis * qhingeorg

				#var q1 = bonenode.global_transform.basis
				#var q2 = bonenodenexthinge.global_transform.basis
				#var Ge1 = q1*e1
				#var Ge2 = q2*e2
				#var Gf2 = q2*f2
				#var Gvang = Vector2(Ge1.dot(Ge2), Ge1.dot(Gf2))
				#var Dqhingeorgangle = fmod(rad_to_deg(Gvang.angle()) + 360.0, 360.0)
				#print(qhingeorgangle, " Grvang ", Dqhingeorgangle, " ", rad_to_deg(hingeaddangrad))


			var jointpos = bonenode.global_transform.origin + bonenode.global_transform.basis*Vector3(0,bonenode.rodlength/2,0) # derivebointjointcentre
			bonenodenexthinge.global_transform.origin = jointpos - bonenodenexthinge.global_transform.basis*Vector3(0,-bonenode.rodlength/2,0)
			
			var Dhingeaxis = bonenode.global_transform.basis*bonenode.jointhingevectortop
			var DhingeaxisN = bonenodenexthinge.global_transform.basis*bonenodenexthinge.jointhingevectorbottom
			if (Dhingeaxis - DhingeaxisN).length() > 0.01:
				print("Dhingeaxis not equal ", Dhingeaxis, DhingeaxisN)

var e1
var e2
var f2

			
func _on_picked_up(pickable):
	controllerpickedby = pickable.by_controller
	if not controllerpickedby.is_button_pressed("trigger_click"):
		if bonenode == null or bonenode.skelbone["bonename"] != bonecontrolname:
			bonenode = get_node("../..").findbonenodefromname(bonecontrolname)
		if bonenode != null:
			if bonenode.jointhingevectortop != null:
				bonenodenexthinge = bonenode.jointobjecttop
				print("next hinge detected ", bonenodenexthinge)
			currentlyheld = true
					
	if currentlyheld:
		controllerlocbasis = transform.basis.inverse()*bonenode.global_transform.basis
		controllerlocorgpos = transform.origin
		bonenodeorgpos = bonenode.global_transform.origin

		var xr_cameraz = get_node("../..").xr_camera.basis.z
		var skelz = bonenode.skelbone["skel"].global_transform.basis.z
		var locangy = Vector2(xr_cameraz.x, xr_cameraz.z).angle_to(Vector2(skelz.x, skelz.z))
		print("locangy ", rad_to_deg(locangy))
		controllerbasisyrot = Basis(Vector3(0,1,0), 0-locangy)


		if bonenodenexthinge != null:
			assert (bonenode.jointobjecttop == bonenodenexthinge)
			assert (bonenode == bonenodenexthinge.jointobjectbottom)
			var q1 = bonenode.global_transform.basis
			var h1 = bonenode.jointhingevectortop
			var v1 = Vector3(0,1,0)
			e1 = (v1 - h1.dot(v1)*h1).normalized()
			
			var q2 = bonenodenexthinge.global_transform.basis
			var h2 = bonenodenexthinge.jointhingevectorbottom
			var v2 = Vector3(0,-1,0)
			e2 = (v2 - h2.dot(v2)*h2).normalized()
			f2 = h2.cross(e2)
			
			var Ge1 = q1*e1
			var Ge2 = q2*e2
			var Gf2 = q2*f2
			var Gvang = Vector2(Ge1.dot(Ge2), Ge1.dot(Gf2))
			qhingeorgangle = fmod(rad_to_deg(Gvang.angle()) + 360.0, 360.0)
			print("Gvang ", Gvang.length(), Gvang, qhingeorgangle)
			
			var hingevec1 = q1*h1
			var hingevec2 = q2*h2

			qhingeorg = q1.inverse()*q2
			var hingevec = q1*h1
			var Dangsin = sin(Dtwave*3)*0.2
			var Dqhingwave = Quaternion(hingevec.x*Dangsin, hingevec.y*Dangsin, hingevec.z*Dangsin, sqrt(1 - Dangsin*Dangsin))

			var Dq2 = Basis(Dqhingwave) * q1*qhingeorg
			
			
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
