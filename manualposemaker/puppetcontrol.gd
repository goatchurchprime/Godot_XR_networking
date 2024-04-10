extends XRToolsPickable

signal pointer_event(event)

const col1 = Color("f98ddd7c")
const col2 = Color("0edf007c")

var controllerpickedby = null
@export var bonecontrolname = "hand .L"

var bonenode = null

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

var controllerlocbasis = null
var controllerbasisyrot = null
var bonenodeorgpos = null
var controllerlocorgpos = null

func _process(delta):
	if bonenode != null:
		bonenode.global_transform.basis = transform.basis * controllerlocbasis
		bonenode.global_transform.origin = bonenodeorgpos + controllerbasisyrot*(transform.origin - controllerlocorgpos)

func _on_picked_up(pickable):
	controllerpickedby = pickable.by_controller
	if not controllerpickedby.is_button_pressed("trigger_click"):
		if bonenode == null or bonenode.skelbone["bonename"] != bonecontrolname:
			bonenode = get_node("../..").findbonenodefromname(bonecontrolname)
	if bonenode != null:
		controllerlocbasis = transform.basis.inverse()*bonenode.global_transform.basis
		controllerlocorgpos = transform.origin
		bonenodeorgpos = bonenode.global_transform.origin

		var xr_cameraz = get_node("../..").xr_camera.basis.z
		var skelz = bonenode.skelbone["skel"].global_transform.basis.z
		var locangy = Vector2(xr_cameraz.x, xr_cameraz.z).angle_to(Vector2(skelz.x, skelz.z))
		print("locangy ", rad_to_deg(locangy))
		controllerbasisyrot = Basis(Vector3(0,1,0), 180-locangy)


func _on_dropped(pickable):
	controllerpickedby = null

func _on_highlight_updated(pickable, enable):
	if enable:
		$MeshInstance3D.get_surface_override_material(0).albedo_color = col2
	else:
		$MeshInstance3D.get_surface_override_material(0).albedo_color = col1
