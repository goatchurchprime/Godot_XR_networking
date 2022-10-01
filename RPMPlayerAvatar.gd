extends Spatial

onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"
onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var Left_hand = arvrorigin.get_node_or_null("Left_hand")
onready var Right_hand = arvrorigin.get_node_or_null("Right_hand")
onready var Configuration = arvrorigin.get_node_or_null("Configuration")
onready var XRPoseLeftHand = arvrorigin.get_node_or_null("Left_hand/XRPose")
onready var XRPoseRightHand = arvrorigin.get_node_or_null("Right_hand/XRPose")

const TRACKING_CONFIDENCE_HIGH = 2

const avatarbodyrotatedegspersec = 90
const avatarbodyrotatedegseasynecklimit = 30

enum {
	CFI_RPMAVATAR_POSITION = 70, 
	CFI_RPMAVATAR_ROTATION = 71, 
	CFI_RPNECK_ROTATION = 72 
}

var rpmavatarskelrestdata = null
func _ready():
	rpmavatarskelrestdata = OpenXRtrackedhand_funcs.getrpmhandrestdata($readyplayerme_avatar)

	var skel = rpmavatarskelrestdata["skel"]
	assert (skel.get_bone_name(4) == "Neck")
	assert (skel.get_bone_name(5) == "Head")
	assert (skel.get_bone_name(7) == "LeftEye")
	assert (skel.get_bone_name(8) == "RightEye")
	assert (skel.get_bone_rest(7).basis.is_equal_approx(skel.get_bone_rest(8).basis))
	rpmavatarskelrestdata["middleeyerestpose"] = Transform(skel.get_bone_rest(7).basis, (skel.get_bone_rest(7).origin + skel.get_bone_rest(8).origin)/2)
	rpmavatarskelrestdata["eyeballdepth"] = skel.get_node("EyeLeft").get_aabb().size.z
	rpmavatarskelrestdata["globalheadrestpose"] = skel.get_bone_global_pose(4)*skel.get_bone_rest(5)

var eyebodyangle = 0.0
func processbodyneckorientation(delta):
	var skel = rpmavatarskelrestdata["skel"] # $readyplayerme_avatar/Armature/Skeleton
	var vrheadcam = $HeadCam.transform
	
	if abs(eyebodyangle) > avatarbodyrotatedegseasynecklimit:
		$readyplayerme_avatar.rotation_degrees.y += avatarbodyrotatedegspersec*delta*sign(eyebodyangle)
	
	var rpmheadcambasis = Basis(-vrheadcam.basis.x, vrheadcam.basis.y, -vrheadcam.basis.z)
	var rpmheadcamposition = vrheadcam.origin - rpmheadcambasis.z*rpmavatarskelrestdata["eyeballdepth"]
	var rpmheadcam = Transform(rpmheadcambasis, rpmheadcamposition)
	var nktrans = rpmheadcam * rpmavatarskelrestdata["middleeyerestpose"].inverse()
	
	var skelbasis = $readyplayerme_avatar.transform.basis * $readyplayerme_avatar/Armature.transform.basis * $readyplayerme_avatar/Armature/Skeleton.transform.basis
	var gpos = nktrans.origin - skelbasis.xform(rpmavatarskelrestdata["globalheadrestpose"].origin)
	var bonepose5basis = (skelbasis * rpmavatarskelrestdata["globalheadrestpose"].basis).inverse()*nktrans.basis
	
	$readyplayerme_avatar.transform.origin = gpos
	skel.set_bone_pose(5, Transform(bonepose5basis))
	
	eyebodyangle = rad2deg(atan2(bonepose5basis.z.x, bonepose5basis.z.z)) if abs(bonepose5basis.z.y) < 0.8 else 0.0

var handtrackingrightvisible = false
var handtrackingleftvisible = false
func processcontrollerhandorientation(delta):
	$ControllerLeft.visible = LeftHandController.get_is_active()
	if $ControllerLeft.visible:
		$ControllerLeft.transform = LeftHandController.transform
	$ControllerRight.visible = RightHandController.get_is_active()
	if $ControllerRight.visible:
		$ControllerRight.transform = RightHandController.transform

	var handtrackingavailable = (arvrorigin.interface != null)
	if handtrackingavailable and is_instance_valid(Right_hand) and Right_hand.is_active():
		var trackingconfidenceRight = XRPoseRightHand.get_tracking_confidence() # see https://github.com/GodotVR/godot_openxr/issues/221
		var h = OpenXRtrackedhand_funcs.gethandjointpositions(Right_hand)
		if trackingconfidenceRight == TRACKING_CONFIDENCE_HIGH and h["ht1"] != Vector3.ZERO: 
			var rpmavatar = rpmavatarskelrestdata["rpmavatar"]
			var skel = rpmavatarskelrestdata["skel"]
			assert (skel.get_bone_name(35) == "RightForeArm")
			var skelrightarmgtrans = skel.global_transform*skel.get_bone_global_pose(35)
			var rpmhandspose = { }
			OpenXRtrackedhand_funcs.setshapetobonesRPM(h, skelrightarmgtrans, rpmhandspose, rpmavatarskelrestdata, false)
			for i in range(36, 57):
				if rpmhandspose.has(i):
					skel.set_bone_pose(i, rpmhandspose[i])
			handtrackingrightvisible = true
		else:
			handtrackingrightvisible = false
	else:
		handtrackingrightvisible = false


func PAV_processlocalavatarposition(delta):
	transform = arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	processbodyneckorientation(delta)
	processcontrollerhandorientation(delta)


func processavatarhand(LR_hand, ovr_LR_hand_model, ControllerLR, ovrhandLRrestdata, LRHandController, XRPoseLRHand):
	var handtrackingavailable = (arvrorigin.interface != null)
	if handtrackingavailable and is_instance_valid(LR_hand) and LR_hand.is_active():
		ControllerLR.visible = false
		var trackingconfidence = XRPoseLRHand.get_tracking_confidence() # see https://github.com/GodotVR/godot_openxr/issues/221
		var h = OpenXRtrackedhand_funcs.gethandjointpositions(LR_hand)
		if trackingconfidence == TRACKING_CONFIDENCE_HIGH and h["ht1"] != Vector3.ZERO: 
			var ovrhandpose = OpenXRtrackedhand_funcs.setshapetobonesOVR(h, ovrhandLRrestdata)
			ovr_LR_hand_model.transform = ovrhandpose["handtransform"]
			var skel = ovrhandLRrestdata["skel"]
			for i in range(23):
				skel.set_bone_pose(i, ovrhandpose[i])
			ovr_LR_hand_model.visible = true
		else:
			ovr_LR_hand_model.visible = false
	elif LRHandController.get_is_active():
		ovr_LR_hand_model.visible = false
		ControllerLR.transform = LRHandController.transform
		ControllerLR.visible = true
	else:
		ovr_LR_hand_model.visible = false
		ControllerLR.visible = false

	#transform.origin += Vector3(0,0,-2)

func PAV_avatartoframedata():
	var skel = rpmavatarskelrestdata["skel"]
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 

				CFI_RPMAVATAR_POSITION: $readyplayerme_avatar.transform.origin, 
				CFI_RPMAVATAR_ROTATION: $readyplayerme_avatar.transform.basis.get_rotation_quat(), 
				CFI_RPNECK_ROTATION: skel.get_bone_pose(5).basis.get_rotation_quat()
			 }
			
	if $ControllerLeft.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ControllerLeft.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ControllerLeft.transform.basis.get_rotation_quat()
	elif handtrackingleftvisible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0
			
	if $ControllerRight.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $ControllerRight.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $ControllerRight.transform.basis.get_rotation_quat()
	elif handtrackingrightvisible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 0.0
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 0.0

	return fd

func overwritetranform(orgtransform, rot, pos):
	if rot == null:
		if pos == null:
			return orgtransform
		return Transform(orgtransform.basis, pos)
	if pos == null:
		return Transform(Basis(rot), orgtransform.origin)
	return Transform(Basis(rot), pos)

func PAV_framedatatoavatar(fd):
	transform = overwritetranform(transform, fd.get(NCONSTANTS2.CFI_VRORIGIN_ROTATION), fd.get(NCONSTANTS2.CFI_VRORIGIN_POSITION))
	$readyplayerme_avatar.transform = overwritetranform($readyplayerme_avatar.transform, fd.get(CFI_RPMAVATAR_ROTATION), fd.get(CFI_RPMAVATAR_POSITION))
	var skel = rpmavatarskelrestdata["skel"]
	var hrot = fd.get(CFI_RPNECK_ROTATION)
	if hrot != null:
		skel.set_bone_pose(5, Transform(hrot))

	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE):
		var hcleftfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE)
		$ControllerLeft.visible = (hcleftfade > 0.0)
	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
		var hcrightfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE)
		$ControllerRight.visible = (hcrightfade > 0.0)
	if $ControllerLeft.visible:
		$ControllerLeft.transform = overwritetranform($ControllerLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
	if $ControllerRight.visible:
		$ControllerRight.transform = overwritetranform($ControllerRight.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))


func PAV_initavatarlocal():
	labeltext = "ding"

func PAV_initavatarremote(avatardata):
	labeltext = avatardata["labeltext"]

func PAV_avatarinitdata():
	var avatardata = { "avatarsceneresource":filename, 
					   "labeltext":labeltext
					 }
	return avatardata

static func PAV_changethinnedframedatafordoppelganger(fd, doppelnetoffset, isframe0):
	fd[NCONSTANTS.CFI_TIMESTAMP] += doppelnetoffset
	fd[NCONSTANTS.CFI_TIMESTAMPPREV] += doppelnetoffset
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_POSITION):
		if isframe0:
			fd[NCONSTANTS2.CFI_VRORIGIN_POSITION].z += -2
		else:
			fd.erase(NCONSTANTS2.CFI_VRORIGIN_POSITION)
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_ROTATION):
		fd[NCONSTANTS2.CFI_VRORIGIN_ROTATION] *= Quat(Vector3(0, 1, 0), deg2rad(180))
