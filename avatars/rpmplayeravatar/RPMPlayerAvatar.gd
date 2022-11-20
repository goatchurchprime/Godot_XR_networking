extends Spatial

onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"
onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var OpenXRallhandsdata = arvrorigin.get_node_or_null("OpenXRallhandsdata")

const TRACKING_CONFIDENCE_HIGH = 2

const avatarbodyrotatedegspersec = 90
const avatarbodyrotatedegseasynecklimit = 30

enum {
	CFI_RPMAVATAR_POSITION = 70, 
	CFI_RPMAVATAR_ROTATION = 71, 
	CFI_RPMNECK_ROTATION = 72, 
	CFI_RPMAVATAR_HANDBONES_ROTATION = 300, 
	CFI_RPMAVATAR_HANDBONES_POSITION = 400 
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
func processbodyneckorientation(delta, vrheadcam):
	var skel = rpmavatarskelrestdata["skel"] # $readyplayerme_avatar/Armature/Skeleton
	
	if abs(eyebodyangle) > avatarbodyrotatedegseasynecklimit:
		$readyplayerme_avatar.rotation_degrees.y += avatarbodyrotatedegspersec*delta*sign(eyebodyangle)
	
	var rpmheadcambasis = Basis(-vrheadcam.basis.x, vrheadcam.basis.y, -vrheadcam.basis.z)
	var rpmheadcamposition = vrheadcam.origin + rpmheadcambasis.z*rpmavatarskelrestdata["eyeballdepth"]
	var rpmheadcam = Transform(rpmheadcambasis, rpmheadcamposition)
	var nktrans = rpmheadcam * rpmavatarskelrestdata["middleeyerestpose"].inverse()
	
	var skelbasis = $readyplayerme_avatar.transform.basis * $readyplayerme_avatar/Armature.transform.basis * $readyplayerme_avatar/Armature/Skeleton.transform.basis
	var gpos = nktrans.origin - skelbasis.xform(rpmavatarskelrestdata["globalheadrestpose"].origin)
	var bonepose5basis = (skelbasis * rpmavatarskelrestdata["globalheadrestpose"].basis).inverse()*nktrans.basis
	
	$readyplayerme_avatar.transform.origin = gpos
	skel.set_bone_pose(5, Transform(bonepose5basis))
	
	eyebodyangle = rad2deg(atan2(bonepose5basis.z.x, bonepose5basis.z.z)) if abs(bonepose5basis.z.y) < 0.8 else 0.0


func processRPMavatarhand(palm_joint_confidence, joint_transforms, rpmavatarskelrestdata, ControllerLR, LRHandController, bright):
	var handtrackinglrvisible = false
	var di = 0 if bright else 24
	if palm_joint_confidence != -1:
		ControllerLR.visible = false
		var h = OpenXRtrackedhand_funcs.gethandjointpositionsL(joint_transforms)
		if palm_joint_confidence == TRACKING_CONFIDENCE_HIGH: 
			var rpmavatar = rpmavatarskelrestdata["rpmavatar"]
			var skel = rpmavatarskelrestdata["skel"]
			var skeltrans = $readyplayerme_avatar.transform * $readyplayerme_avatar/Armature.transform * $readyplayerme_avatar/Armature/Skeleton.transform
			var skelshouldertrans = skeltrans*skel.get_bone_global_pose(33-di)
			var skelarmrest = skelshouldertrans*rpmavatarskelrestdata[34-di]
			var rpmhandspose = { }
			OpenXRtrackedhand_funcs.setshapetobonesRPM(h, skelarmrest, rpmhandspose, rpmavatarskelrestdata, bright)
			for i in range(34-di, 57-di):
				skel.set_bone_pose(i, rpmhandspose[i])
				if i <= 36-di:  # force arms not to change their length
					skel.set_bone_pose(i, Transform(rpmhandspose[i].basis))
			handtrackinglrvisible = true
	elif LRHandController.get_is_active():
		ControllerLR.transform = LRHandController.transform
		ControllerLR.visible = true
	else:
		ControllerLR.visible = false
	return handtrackinglrvisible


var handtrackingrightvisible = false
var handtrackingleftvisible = false
func PAV_processlocalavatarposition(delta):
	transform = arvrorigin.transform
	var vrheadcam = arvrorigin.get_node("ARVRCamera").transform
	$HeadCam.transform = Transform(vrheadcam.basis, vrheadcam.origin+Vector3(0,0.5,0))
	processbodyneckorientation(delta, vrheadcam)

	handtrackingleftvisible = processRPMavatarhand(OpenXRallhandsdata.palm_joint_confidence_L, OpenXRallhandsdata.joint_transforms_L, rpmavatarskelrestdata, $ControllerLeft, LeftHandController, false)
	handtrackingrightvisible = processRPMavatarhand(OpenXRallhandsdata.palm_joint_confidence_L, OpenXRallhandsdata.joint_transforms_R, rpmavatarskelrestdata, $ControllerRight, RightHandController, true)

func PAV_avatartoframedata():
	var skel = rpmavatarskelrestdata["skel"]
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quat(), 

				CFI_RPMAVATAR_POSITION: $readyplayerme_avatar.transform.origin, 
				CFI_RPMAVATAR_ROTATION: $readyplayerme_avatar.transform.basis.get_rotation_quat(), 
				CFI_RPMNECK_ROTATION: skel.get_bone_pose(5).basis.get_rotation_quat()
			 }
			
	if handtrackingleftvisible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = -1.0
		for i in range(34-24, 57-24):
			fd[CFI_RPMAVATAR_HANDBONES_ROTATION+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	elif $ControllerLeft.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ControllerLeft.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ControllerLeft.transform.basis.get_rotation_quat()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0
			
	if handtrackingrightvisible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = -1.0
		for i in range(34, 57):
			fd[CFI_RPMAVATAR_HANDBONES_ROTATION+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	elif $ControllerRight.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $ControllerRight.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $ControllerRight.transform.basis.get_rotation_quat()
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
	$HeadCam.transform = overwritetranform($HeadCam.transform, fd.get(NCONSTANTS2.CFI_VRHEAD_ROTATION), fd.get(NCONSTANTS2.CFI_VRHEAD_POSITION))

	var skel = rpmavatarskelrestdata["skel"]
	var hrot = fd.get(CFI_RPMNECK_ROTATION)
	if hrot != null:
		skel.set_bone_pose(5, Transform(hrot))

	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE):
		var hcleftfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE)
		$ControllerLeft.visible = (hcleftfade > 0.0)
		handtrackingleftvisible = (hcleftfade < 0.0)
	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
		var hcrightfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE)
		$ControllerRight.visible = (hcrightfade > 0.0)
		handtrackingrightvisible = (hcrightfade < 0.0)
		
	if handtrackingrightvisible:
		for i in range(34, 57):
			var frot = fd.get(CFI_RPMAVATAR_HANDBONES_ROTATION+i)
			if frot != null:
				skel.set_bone_pose(i, Transform(frot))
		#skel.set_bone_pose(35, overwritetranform(skel.get_bone_pose(35), fd.get(CFI_RPMAVATAR_HANDBONES_ROTATION+35), fd.get(CFI_RPMAVATAR_HANDBONES_POSITION+35)))

	elif $ControllerRight.visible:
		$ControllerRight.transform = overwritetranform($ControllerRight.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))

	if handtrackingleftvisible:
		for i in range(34-24, 57-24):
			var frot = fd.get(CFI_RPMAVATAR_HANDBONES_ROTATION+i)
			if frot != null:
				skel.set_bone_pose(i, Transform(frot))
		#skel.set_bone_pose(35-24, overwritetranform(skel.get_bone_pose(35-24), fd.get(CFI_RPMAVATAR_HANDBONES_ROTATION+35-24), fd.get(CFI_RPMAVATAR_HANDBONES_POSITION+35-24)))

	elif $ControllerLeft.visible:
		$ControllerLeft.transform = overwritetranform($ControllerLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))



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
