extends Spatial

onready var FPController = get_node("../FPController")
onready var OpenXRallhandsdata = get_node("../FPController/OpenXRallhandsdata")

var loriencavassizescalingfac = Vector2(1, 1)

func _ready():
	if has_node("ViewportLorienCanvas"):
#		$ViewportLorienCanvas.connect("pointer_entered", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "enable")
#		$ViewportLorienCanvas.connect("pointer_exited", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "disable")
		var project = ProjectManager.add_project()
		ProjectManager.make_project_active(project)
		$ViewportLorienCanvas/Viewport/InfiniteCanvas.use_project(project)

	$ViewportLorienCanvas/Viewport/InfiniteCanvas.enable()
	var screen_size = $ViewportLorienCanvas.screen_size
	var viewport_size = $ViewportLorienCanvas.viewport_size
	loriencavassizescalingfac = Vector2(viewport_size.x/screen_size.x, -viewport_size.y/screen_size.y)

var Dw = 2

var activefingerheight = 0.018
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
	if flathandscore > 0.0:
		var palmtransform = FPController.global_transform*joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_PALM_EXT]
		$flathandmarker.get_surface_material(0).albedo_color.a = flathandscore
		$flathandmarker.transform.origin = palmtransform.origin
		if flathandscore >= 0.5:
			if $flathandmarker.scale.z == 0.0:
				$flathandmarker.visible = true
			if $flathandmarker.visible:
				$flathandmarker.rotation_degrees.y = 90-rad2deg(Vector2(palmtransform.basis.z.x, palmtransform.basis.z.z).angle())
				$flathandmarker.scale.z = min(1.0, $flathandmarker.scale.z + delta/1.1)
				if $flathandmarker.scale.z == 1.0:
					print("Reset position ", palmtransform.origin)
					$ViewportLorienCanvas.translation = palmtransform.origin - Vector3(0, flathandsurfacedepth, 0)
					$flathandmarker.visible = false
					return true
	if flathandscore < 0.5:
		if $flathandmarker.scale.z != 0.0:
			$flathandmarker.scale.z = max(0.0, $flathandmarker.scale.z - delta/0.5)
			if $flathandmarker.scale.z == 0.0:
				$flathandmarker.visible = false
	return false
	
var panvec = Vector2(0,0)
func setshrinkavatartransform():
	return
	var LocalPlayer = get_node("..").NetworkGateway.get_node("PlayerConnections").LocalPlayer
	var shrinkfactor = 0.2
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
		flathandactive = 0 if $flathandmarker.scale.z == 0.0 else 1 
	if flathandactive != 1:
		resetflat = flathandresetdetection(OpenXRallhandsdata.joint_transforms_R, flathandscoreR, delta)
		flathandactive = 0 if $flathandmarker.scale.z == 0.0 else 2 
	if resetflat:
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
			var handposscore = clamp(1 - abs(handposabovetable)/lorientcanvasknucklethickness, 0, 1)
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
		var kvec = $ViewportLorienCanvas.transform.basis.xform_inv(kpvec)
		var svec = Vector2(kvec.x*loriencavassizescalingfac.x, kvec.y*loriencavassizescalingfac.y)
		$ViewportLorienCanvas/Viewport/InfiniteCanvas/Viewport/Camera2D._do_pan(svec)
		#print("ss ", svec)
#			panvec += svec
#			var LocalPlayer = get_node("..").NetworkGateway.get_node("PlayerConnections").LocalPlayer
#			var shrinkfactor = 0.2
#			var shrinkorigin = $ViewportLorienCanvas.translation + Vector3(panvec.x, 0, panvec.y)
#			$shrinkavatartransform.transform = Transform(Basis().scaled(Vector3(shrinkfactor,shrinkfactor,shrinkfactor)), shrinkorigin*(1 - shrinkfactor))
#			LocalPlayer.shrinkavatartransform = $shrinkavatartransform.transform
#			LocalPlayer.get_node("HeadCam").visible = false




func _physics_process(delta):
	flathandsresetdetection(delta)
	sidehanddragdetection(delta)
	
	if OpenXRallhandsdata.is_active_R:
		$RightIndexFinger.global_transform = FPController.global_transform*OpenXRallhandsdata.joint_transforms_R[OpenXRallhandsdata.XR_HAND_JOINT_INDEX_TIP_EXT]
	if OpenXRallhandsdata.is_active_L:
		$LeftIndexFinger.global_transform = FPController.global_transform*OpenXRallhandsdata.joint_transforms_L[OpenXRallhandsdata.XR_HAND_JOINT_INDEX_TIP_EXT]
	
	var p_at = $RightIndexFinger.transform.origin
	var indexfingerpos = $ViewportLorienCanvas.transform.xform_inv(p_at)

	if indexfingerpos.z > -activefingerheight and indexfingerpos.z < activefingerheight:
		var screen_size = $ViewportLorienCanvas.screen_size
		var viewport_size = $ViewportLorienCanvas.viewport_size
		var ax = ((indexfingerpos.x / screen_size.x) + 0.5) * viewport_size.x
		var ay = (0.5 - (indexfingerpos.y / screen_size.y)) * viewport_size.y
		var vpfingerpos = Vector2(ax, ay)

		if not indexfingerActive:
			var event = InputEventMouseButton.new()
			event.set_button_index(BUTTON_LEFT)
			event.set_pressed(true)
			event.set_position(vpfingerpos)
			event.set_global_position(vpfingerpos)
			event.set_button_mask(1)
			$ViewportLorienCanvas/Viewport.input(event)
			indexfingerActive = true
			$RightIndexFinger/ActiveMarker.visible = true
			
		var vpfingervec = vpfingerpos - vpfingerposPrev 
		if vpfingervec.length() > 0.004:
			var event = InputEventMouseMotion.new()
			event.set_position(vpfingerpos)
			event.set_global_position(vpfingerpos)
			event.set_relative(vpfingervec)
			event.set_button_mask(1)
			event.set_pressure(min(1.0, 1.0 + indexfingerpos.z/activefingerheight))
			$ViewportLorienCanvas/Viewport.input(event)
			vpfingerposPrev = vpfingerpos
		
	elif indexfingerActive:
		var event = InputEventMouseButton.new()
		event.set_button_index(BUTTON_LEFT)
		event.set_pressed(false)
		event.set_position(vpfingerposPrev)
		event.set_global_position(vpfingerposPrev)
		event.set_button_mask(0)
		$ViewportLorienCanvas/Viewport.input(event)
		indexfingerActive = false
		$RightIndexFinger/ActiveMarker.visible = false

