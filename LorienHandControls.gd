extends Spatial

onready var FPController = get_node("../FPController")
onready var OpenXRallhandsdata = get_node("../FPController/OpenXRallhandsdata")

func _ready():
	if has_node("ViewportLorienCanvas"):
#		$ViewportLorienCanvas.connect("pointer_entered", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "enable")
#		$ViewportLorienCanvas.connect("pointer_exited", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "disable")
		var project = ProjectManager.add_project()
		ProjectManager.make_project_active(project)
		$ViewportLorienCanvas/Viewport/InfiniteCanvas.use_project(project)

	$ViewportLorienCanvas/Viewport/InfiniteCanvas.enable()

var Dw = 2
func _on_AreaZoom_body_entered(body):
	print("_on_AreaResetpos_body_entered ", body)
	var event = InputEventMouseButton.new()
	Dw += 1
	event.set_button_index(BUTTON_WHEEL_DOWN if (Dw%10)<5 else BUTTON_WHEEL_UP)
	event.set_position(Vector2(300,200))
	event.set_global_position(Vector2(300,200))
	event.set_pressed(true)
	event.set_button_mask(0)
	#$ViewportLorienCanvas/Viewport.input(event)  # not getting cycled through as the tool event
	$ViewportLorienCanvas/Viewport/InfiniteCanvas/Viewport/Camera2D.tool_event(event)

var activefingerheight = 0.018
var vpfingerposPrev = Vector2(0,0)
var indexfingerActive = false
var LvpfingerposPrev = Vector2(0,0)
var LindexfingerActive = false

var bfistdetected = false

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
	if flathandscore < 0.5:
		if $flathandmarker.scale.z != 0.0:
			$flathandmarker.scale.z = max(0.0, $flathandmarker.scale.z - delta/0.5)
			if $flathandmarker.scale.z == 0.0:
				$flathandmarker.visible = false

var flathandactive = 0
func flathandsresetdetection(delta):
	var flathandscoreL = flathandscore(OpenXRallhandsdata.joint_transforms_L) if (OpenXRallhandsdata.is_active_L and OpenXRallhandsdata.palm_joint_confidence_L == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else 0.0
	var flathandscoreR = flathandscore(OpenXRallhandsdata.joint_transforms_R) if (OpenXRallhandsdata.is_active_R and OpenXRallhandsdata.palm_joint_confidence_R == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else 0.0
	if flathandactive != 2:
		flathandresetdetection(OpenXRallhandsdata.joint_transforms_L, flathandscoreL, delta)
		flathandactive = 0 if $flathandmarker.scale.z == 0.0 else 1 
	if flathandactive != 1:
		flathandresetdetection(OpenXRallhandsdata.joint_transforms_R, flathandscoreR, delta)
		flathandactive = 0 if $flathandmarker.scale.z == 0.0 else 2 

var sinpalmsidedirectionrange = sin(deg2rad(20))
var sidehandheighttarget = 0.10
func sidehandscore(joint_transforms):
	var palmbasis = joint_transforms[OpenXRallhandsdata.XR_HAND_JOINT_PALM_EXT].basis
	var palmsidedirectionscore = clamp(inverse_lerp(sinpalmsidedirectionrange, 0, abs(palmbasis.y.y)), 0, 1)
	if palmsidedirectionscore > 0.0:
		var handheight = detectfingersext(joint_transforms, palmbasis.x, OpenXRallhandsdata.xrbones_necessary_to_measure_extent)
		var handheightscore = clamp(inverse_lerp(sidehandheighttarget*0.75, sidehandheighttarget, handheight), 0, 1)
		if handheightscore > 0.0:
			return (palmsidedirectionscore + handheightscore)/2
	return 0.0

func sidehandvector(littleknucklepos, fistdragmarker):
	var svecL = Vector2(0,0)
	if fistdragmarker.visible:
		var kpvec = littleknucklepos - fistdragmarker.translation
		var kvec = $ViewportLorienCanvas.transform.basis.xform_inv(kpvec)
		svecL = Vector2(kvec.x*loriencavassizescalingfac.x, kvec.y*loriencavassizescalingfac.y)
	else:
		fistdragmarker.visible = true
		var screen_size = $ViewportLorienCanvas.screen_size
		var viewport_size = $ViewportLorienCanvas.viewport_size
		loriencavassizescalingfac = Vector2(viewport_size.x/screen_size.x, -viewport_size.y/screen_size.y)
	fistdragmarker.translation = Vector3(littleknucklepos.x, littleknucklepos.y + fistdragmarker.scale.y*fistdragmarker.mesh.size.y*0.5, littleknucklepos.z)
	return svecL

var loriencavassizescalingfac = Vector2(1, 1)
var lorientcanvasknucklethickness = 0.02
func sidehanddragdetection():
	var flathandscoreL = sidehandscore(OpenXRallhandsdata.joint_transforms_L) if (OpenXRallhandsdata.is_active_L and OpenXRallhandsdata.palm_joint_confidence_L == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else 0.0
	var flathandscoreR = sidehandscore(OpenXRallhandsdata.joint_transforms_R) if (OpenXRallhandsdata.is_active_R and OpenXRallhandsdata.palm_joint_confidence_R == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH) else 0.0

	var svec = Vector2(0,0)

	if flathandscoreL >= 0.4:
		var littleknuckleposL = FPController.global_transform*OpenXRallhandsdata.joint_transforms_L[OpenXRallhandsdata.XR_HAND_JOINT_LITTLE_PROXIMAL_EXT].origin
		if abs(littleknuckleposL.y - $ViewportLorienCanvas.translation.y) < lorientcanvasknucklethickness:
			svec += sidehandvector(littleknuckleposL, $fistdragmarkerL)
			$fistdragmarkerL.get_surface_material(0).albedo_color.a = flathandscoreL
		else:
			flathandscoreL = 0.0
	if flathandscoreL < 0.4:
		$fistdragmarkerL.visible = false

	if flathandscoreR >= 0.4:
		var littleknuckleposR = FPController.global_transform*OpenXRallhandsdata.joint_transforms_R[OpenXRallhandsdata.XR_HAND_JOINT_LITTLE_PROXIMAL_EXT].origin
		if abs(littleknuckleposR.y - $ViewportLorienCanvas.translation.y) < lorientcanvasknucklethickness:
			svec += sidehandvector(littleknuckleposR, $fistdragmarkerR)
			$fistdragmarkerR.get_surface_material(0).albedo_color.a = flathandscoreR
		else:
			flathandscoreR = 0.0
	if flathandscoreR < 0.4:
		$fistdragmarkerR.visible = false

	if svec.length() > 0.001:
		$ViewportLorienCanvas/Viewport/InfiniteCanvas/Viewport/Camera2D._do_pan(svec)


func _physics_process(delta):
	flathandsresetdetection(delta)
	sidehanddragdetection()
	
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

