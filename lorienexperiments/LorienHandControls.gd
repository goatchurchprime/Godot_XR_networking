extends Spatial

onready var FPController = get_node("../FPController")
onready var OpenXRallhandsdata = get_node("../FPController/OpenXRallhandsdata")

var loriencavassizescalingfac = Vector2(1,1)
var loriencanvasviewportsize = Vector2(1,1)
var loriencavasscreensize = Vector2(1,1)

func _ready():
	if has_node("ViewportLorienCanvas"):
#		$ViewportLorienCanvas.connect("pointer_entered", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "enable")
#		$ViewportLorienCanvas.connect("pointer_exited", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "disable")
		var project = ProjectManager.add_project()
		ProjectManager.make_project_active(project)
		$ViewportLorienCanvas/Viewport/InfiniteCanvas.use_project(project)

	$ViewportLorienCanvas/Viewport/InfiniteCanvas.enable()
	loriencavasscreensize = $ViewportLorienCanvas.screen_size
	loriencanvasviewportsize = $ViewportLorienCanvas.viewport_size
	loriencavassizescalingfac = Vector2(loriencanvasviewportsize.x/loriencavasscreensize.x, -loriencanvasviewportsize.y/loriencavasscreensize.y)
	$ViewportLorienCanvas/Viewport/InfiniteCanvas.set_brush_size(4.0)

	var handuihook = FPController.get_node("LeftHandController/HandUIHook")
	handuihook.remote_path = handuihook.get_path_to($lorienUI)

	$lorienUI/Viewport/Control/record.connect("toggled", self, "recordbutton")

func recordbutton(button_pressed: bool):
	print("recordbuttonrecordbutton ", button_pressed)
	

var Dw = 2

var vpfingerposPrev = Vector2(0,0)
var indexfingerActive = false
var LvpfingerposPrev = Vector2(0,0)
var LindexfingerActive = false


func detectfingersext(joint_transforms, vec, xrlist):
	var lo = 0.0
	var hi = 0.0
	for i in range(len(xrlist)):
		var v = vec.dot(joint_transforms[xrlist[i]].origin)
		if i == 0 or v < lo:  lo = v
		if i == 0 or v > hi:  hi = v
	return hi - lo

var sinpalmdowndirectionrange = sin(deg2rad(65))
var palmdepthtarget = 0.013
var palmwidthtarget = 0.197
var palmextenttarget = 0.138
func flathandscore(joint_transforms):
	var palmbasis = joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_PALM_EXT].basis
	var palmscore = 0.0
	var palmdowndirectionscore = clamp(inverse_lerp(sinpalmdowndirectionrange, 1, palmbasis.y.y), 0, 1)
	if palmdowndirectionscore > 0.0:
		var handdepth = detectfingersext(joint_transforms, palmbasis.y, OpenXRallhandsdata.xrbones_necessary_to_measure_extent)
		var palmdepthscore = clamp(inverse_lerp(palmdepthtarget*3.5, palmdepthtarget*1.1, handdepth), 0, 1)
		if palmdepthscore > 0.0:
			var handwidth = detectfingersext(joint_transforms, palmbasis.x, OpenXRallhandsdata.xrbones_necessary_to_measure_extent)
			var palmwidthscore = clamp(inverse_lerp(palmwidthtarget*0.75, palmwidthtarget, handwidth), 0, 1)
			if palmwidthscore > 0.0:
				var handextent = detectfingersext(joint_transforms, palmbasis.z, OpenXRallhandsdata.xrbones_necessary_to_measure_extent)
				palmscore = (palmdowndirectionscore + palmdepthscore + palmwidthscore)/3
	return palmscore
	
var flathandsurfacedepth = 0.020
func flathandresetdetection(joint_transforms, flathandscore, delta):
	var flathandmarker = $shrinkavatartransform/flathandmarker
	if flathandscore > 0.0:
		var palmtransform = FPController.global_transform*joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_PALM_EXT]
		flathandmarker.get_surface_material(0).albedo_color.a = flathandscore
		flathandmarker.transform.origin = palmtransform.origin
		if flathandscore >= 0.5:
			if flathandmarker.scale.z == 0.0:
				flathandmarker.visible = true
			if flathandmarker.visible:
				flathandmarker.rotation_degrees.y = 90-rad2deg(Vector2(palmtransform.basis.z.x, palmtransform.basis.z.z).angle())
				flathandmarker.scale.z = min(1.0, flathandmarker.scale.z + delta/1.1)
				if flathandmarker.scale.z == 1.0:
					print("Reset position ", palmtransform.origin)
					$ViewportLorienCanvas.translation = palmtransform.origin - Vector3(0, flathandsurfacedepth, 0)
					flathandmarker.visible = false
					return true
	if flathandscore < 0.5:
		if flathandmarker.scale.z != 0.0:
			flathandmarker.scale.z = max(0.0, flathandmarker.scale.z - delta/0.5)
			if flathandmarker.scale.z == 0.0:
				flathandmarker.visible = false
	return false
	
var panvec = Vector2(0,0)
var shrinkfactor = 1.0
func setshrinkavatartransform():
	var LocalPlayer = get_node("..").NetworkGateway.get_node("PlayerConnections").LocalPlayer
	var shrinkorigin = $ViewportLorienCanvas.translation + Vector3(panvec.x, 0, panvec.y)
	$shrinkavatartransform.transform = Transform(Basis().scaled(Vector3(shrinkfactor,shrinkfactor,shrinkfactor)), shrinkorigin*(1 - shrinkfactor))
	LocalPlayer.shrinkavatartransform = $shrinkavatartransform.transform
	LocalPlayer.get_node("HeadCam").visible = false


var flathandactive = 0
func flathandsresetdetection(delta):
	var flathandscoreL = flathandscore(OpenXRallhandsdata.joint_transforms_L) if (OpenXRallhandsdata.is_active_L and OpenXRallhandsdata.palm_joint_confidence_L == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else 0.0
	var flathandscoreR = flathandscore(OpenXRallhandsdata.joint_transforms_R) if (OpenXRallhandsdata.is_active_R and OpenXRallhandsdata.palm_joint_confidence_R == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else 0.0
	var resetflat = false
	if flathandactive != 2:
		resetflat = flathandresetdetection(OpenXRallhandsdata.joint_transforms_L, flathandscoreL, delta)
		flathandactive = 0 if $shrinkavatartransform/flathandmarker.scale.z == 0.0 else 1 
	if flathandactive != 1:
		resetflat = flathandresetdetection(OpenXRallhandsdata.joint_transforms_R, flathandscoreR, delta)
		flathandactive = 0 if $shrinkavatartransform/flathandmarker.scale.z == 0.0 else 2 
	if resetflat:
		if shrinkfactor == 1.0:
			shrinkfactor = 0.5
		else:
			shrinkfactor = 1.0
			panvec = Vector2(0,0)
		setshrinkavatartransform()

var sinpalmsidedirectionrange = sin(deg2rad(20))
var sidehandheighttarget = 0.09
func sidehandvector(joint_transforms, fistdragmarker, delta):
	var palmbasis = FPController.global_transform.basis*joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_PALM_EXT].basis
	var palmsidedirectionscore = clamp(inverse_lerp(sinpalmsidedirectionrange, 0, abs(palmbasis.y.y)), 0, 1)
	var littleknucklepos = null 
	var flathandscore = 0.0
	if palmsidedirectionscore > 0.0:
		var handheight = detectfingersext(joint_transforms, palmbasis.x, OpenXRallhandsdata.xrbones_necessary_to_measure_extent)
		var handheightscore = clamp(inverse_lerp(sidehandheighttarget*0.75, sidehandheighttarget, handheight), 0, 1)
		if handheightscore > 0.0:
			littleknucklepos = FPController.global_transform*joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_LITTLE_PROXIMAL_EXT].origin
			var handposabovetable = littleknucklepos.y - $ViewportLorienCanvas.translation.y
			var handposscore = clamp(1 - abs(handposabovetable)/(lorientcanvasknucklethickness*shrinkfactor), 0, 1)
			if handposscore > 0.0:
				flathandscore = (palmsidedirectionscore + handheightscore + handposscore)/3
			
	fistdragmarker.get_surface_material(0).albedo_color.a = flathandscore
	if flathandscore >= 0.4 and littleknucklepos != null:
		var kpvec = null
		fistdragmarker.scale.z = 1.0
		if fistdragmarker.visible:
			kpvec = littleknucklepos - fistdragmarker.translation
			if kpvec.length() < 0.001:
				return null
		else:
			fistdragmarker.visible = true
		fistdragmarker.translation = Vector3(littleknucklepos.x, littleknucklepos.y + fistdragmarker.scale.y*fistdragmarker.mesh.size.y*0.5, littleknucklepos.z)
		return kpvec

	if fistdragmarker.visible:
		fistdragmarker.scale.z = max(0.0, fistdragmarker.scale.z - delta/0.3)
		if fistdragmarker.scale.z == 0.0:
			fistdragmarker.visible = false
	return null


var lorientcanvasknucklethickness = 0.02
func sidehanddragdetection(delta):
	var kpvecL = sidehandvector(OpenXRallhandsdata.joint_transforms_L, $shrinkavatartransform/fistdragmarkerL, delta) if (OpenXRallhandsdata.is_active_L and OpenXRallhandsdata.palm_joint_confidence_L == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else null
	var kpvecR = sidehandvector(OpenXRallhandsdata.joint_transforms_R, $shrinkavatartransform/fistdragmarkerR, delta) if (OpenXRallhandsdata.is_active_R and OpenXRallhandsdata.palm_joint_confidence_R == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else null
	if kpvecL != null or kpvecR != null:
		var kpvec = (kpvecL if kpvecL != null else Vector3(0,0,0)) + (kpvecR if kpvecR != null else Vector3(0,0,0))
		if true or shrinkfactor == 1.0:
			var kvec = $ViewportLorienCanvas.transform.basis.xform_inv(kpvec)
			var svec = shrinkfactor*Vector2(kvec.x*loriencavassizescalingfac.x, kvec.y*loriencavassizescalingfac.y)
			$ViewportLorienCanvas/Viewport/InfiniteCanvas/Viewport/Camera2D._do_pan(svec)
		else:
			panvec += -shrinkfactor*Vector2(kpvec.x, kpvec.z)
			setshrinkavatartransform()

var flatpenanglelimit = sin(deg2rad(15))
var activefingerheight = 0.018
var cursorfingerheight = 0.300
var penmarkerspos = Vector2(0,0)
func penmarkerdetection(joint_transforms, penmarker, delta, bdisable):
	var lpenmarkertransform = FPController.global_transform*OpenXRallhandsdata.joint_transforms_R[OpenXRallhandsdata.XR_HAND_JOINT_INDEX_TIP_EXT]
	penmarker.visible = not bdisable
	if bdisable:
		return
	var lpenmarkershrinkedorigin = $shrinkavatartransform.transform.xform(lpenmarkertransform.origin)
	var penposabovetable = (lpenmarkershrinkedorigin.y - $ViewportLorienCanvas.translation.y)/shrinkfactor
	if penposabovetable > cursorfingerheight:
		return
	var kpos = $ViewportLorienCanvas.transform.xform_inv(lpenmarkershrinkedorigin)
	var spos = Vector2(((kpos.x / loriencavasscreensize.x) + 0.5) * loriencanvasviewportsize.x, 
					   (0.5 - (kpos.y / loriencavasscreensize.y)) * loriencanvasviewportsize.y)
	var penincontact = (abs(penposabovetable) < activefingerheight) and (lpenmarkertransform.basis.z.y >= flatpenanglelimit)
	var penmarkeractivemarker = penmarker.get_node("ActiveMarker")
	var penmarkercontactchanged = (penincontact != penmarkeractivemarker.visible)
	var sposvec = spos - penmarkerspos
	if sposvec.length() < 0.001 and (not penmarkercontactchanged):
		return
	var buttonmask = (1 if penincontact else 0)
	if penmarkercontactchanged:
		var mousebuttonevent = InputEventMouseButton.new()
		mousebuttonevent.set_button_index(BUTTON_LEFT)
		mousebuttonevent.set_pressed(penincontact)
		mousebuttonevent.set_position(spos)
		mousebuttonevent.set_global_position(spos)
		mousebuttonevent.set_button_mask(buttonmask)
		$ViewportLorienCanvas/Viewport.input(mousebuttonevent)
		penmarkeractivemarker.visible = penincontact
	var mousemotionevent = InputEventMouseMotion.new()
	mousemotionevent.set_position(spos)
	mousemotionevent.set_global_position(spos)
	mousemotionevent.set_relative(sposvec)
	mousemotionevent.set_button_mask(buttonmask)
	mousemotionevent.set_pressure(1.0)
	$ViewportLorienCanvas/Viewport.input(mousemotionevent)
	penmarkerspos = spos
	penmarker.transform = lpenmarkertransform

func _physics_process(delta):
	flathandsresetdetection(delta)
	sidehanddragdetection(delta)
	if OpenXRallhandsdata.is_active_R:
		if OpenXRallhandsdata.palm_joint_confidence_R == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH:
			penmarkerdetection(OpenXRallhandsdata.joint_transforms_R, $shrinkavatartransform/penmarkerR, delta, ($shrinkavatartransform/flathandmarker.scale.z != 0.0))

	if OpenXRallhandsdata.is_active_R:
		$shrinkavatartransform/RightIndexFinger.transform = FPController.global_transform*OpenXRallhandsdata.joint_transforms_R[OpenXRallhandsdata.XR_HAND_JOINT_INDEX_TIP_EXT]
	if OpenXRallhandsdata.is_active_L:
		$shrinkavatartransform/LeftIndexFinger.transform = FPController.global_transform*OpenXRallhandsdata.joint_transforms_L[OpenXRallhandsdata.XR_HAND_JOINT_INDEX_TIP_EXT]

