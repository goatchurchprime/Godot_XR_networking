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

var ovrhandrightrestdata = null
var ovrhandleftrestdata = null
func _ready():
	ovrhandrightrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_right_hand_model)
	ovrhandleftrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_left_hand_model)
	
func processavatarhand(LR_hand, ovr_LR_hand_model, ControllerLR, ovrhandLRrestdata, LRHandController, XRPoseLRHand):
	var handtrackingavailable = (arvrorigin.interface != null)
	if handtrackingavailable and is_instance_valid(LR_hand) and LR_hand.is_active():
		ControllerLR.visible = false
		var trackingconfidence = XRPoseLRHand.get_tracking_confidence() # see https://github.com/GodotVR/godot_openxr/issues/221
		var h = OpenXRtrackedhand_funcs.gethandjointpositions(LR_hand)
		if trackingconfidence == TRACKING_CONFIDENCE_HIGH and h["ht1"] != Vector3.ZERO: 
			var ovrhandpose = OpenXRtrackedhand_funcs.setshapetobones(h, ovrhandLRrestdata)
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

func processlocalavatarposition(delta):
	transform = arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	processavatarhand(Left_hand, $ovr_left_hand_model, $ControllerLeft, ovrhandleftrestdata, LeftHandController, XRPoseLeftHand)
	processavatarhand(Right_hand, $ovr_right_hand_model, $ControllerRight, ovrhandrightrestdata, RightHandController, XRPoseRightHand)

func setpaddlebody(active):
	$ControllerRight/PaddleBody.visible = active
	$ControllerRight/PaddleBody/CollisionShape.disabled = not active

func avatartoframedata():
	var chleft = $ovr_left_hand_model if $ovr_left_hand_model.visible else $ControllerLeft
	var chright = $ovr_right_hand_model if $ovr_right_hand_model.visible else $ControllerRight

	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quat(), 

				NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE: (-1.0 if $ovr_left_hand_model.visible else (1.0 if $ControllerLeft.visible else 0.0)), 
				NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE: (-1.0 if $ovr_right_hand_model.visible else (1.0 if $ControllerRight.visible else 0.0)),
				
				NCONSTANTS2.CFI_VRHANDLEFT_POSITION: chleft.transform.origin, 
				NCONSTANTS2.CFI_VRHANDLEFT_ROTATION: chleft.transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHANDRIGHT_POSITION: chright.transform.origin, 
				NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION: chright.transform.basis.get_rotation_quat(),

				NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY: $ControllerRight/PaddleBody.visible
			 }

	if $ovr_left_hand_model.visible:
		var skel = ovrhandleftrestdata["skel"]
		for i in range(23):
			fd[NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	if $ovr_right_hand_model.visible:
		var skel = ovrhandrightrestdata["skel"]
		for i in range(23):
			fd[NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quat()

	return fd

func overwritetranform(orgtransform, rot, pos):
	if rot == null:
		if pos == null:
			return orgtransform
		return Transform(orgtransform.basis, pos)
	if pos == null:
		return Transform(Basis(rot), orgtransform.origin)
	return Transform(Basis(rot), pos)

func framedatatoavatar(fd):
	transform = overwritetranform(transform, fd.get(NCONSTANTS2.CFI_VRORIGIN_ROTATION), fd.get(NCONSTANTS2.CFI_VRORIGIN_POSITION))
	$HeadCam.transform = overwritetranform($HeadCam.transform, fd.get(NCONSTANTS2.CFI_VRHEAD_ROTATION), fd.get(NCONSTANTS2.CFI_VRHEAD_POSITION))

	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE):
		var hcleftfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE)
		$ControllerLeft.visible = (hcleftfade > 0.0)
		$ovr_left_hand_model.visible = (hcleftfade < 0.0)
	if fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
		var hcrightfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE)
		$ControllerRight.visible = (hcrightfade > 0.0)
		$ovr_right_hand_model.visible = (hcrightfade < 0.0)
		
	if $ovr_left_hand_model.visible:
		$ovr_left_hand_model.transform = overwritetranform($ovr_left_hand_model.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
		var skel = $ovr_left_hand_model/ArmatureLeft/Skeleton
		for i in range(23):
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose(i, Transform(frot))
	elif $ControllerLeft.visible:
		$ControllerLeft.transform = overwritetranform($ControllerLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))

	if $ovr_right_hand_model.visible:
		$ovr_right_hand_model.transform = overwritetranform($ovr_right_hand_model.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))
		var skel = $ovr_right_hand_model/ArmatureRight/Skeleton
		for i in range(23):
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose(i, Transform(frot))
	elif $ControllerRight.visible:
		$ControllerRight.transform = overwritetranform($ControllerRight.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))

		
	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("remote setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
		setpaddlebody(fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])


		
var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func initavatarlocal():
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]
	$ovr_left_hand_model/ArmatureLeft/Skeleton/l_handMeshNode.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))
	$ovr_right_hand_model/ArmatureRight/Skeleton/r_handMeshNode.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))

func initavatarremote(avatardata):
	labeltext = avatardata["labeltext"]

func avatarinitdata():
	var avatardata = { "avatarsceneresource":filename, 
					   "labeltext":labeltext
					 }
	return avatardata
	

static func changethinnedframedatafordoppelganger(fd, doppelnetoffset, isframe0):
	fd[NCONSTANTS.CFI_TIMESTAMP] += doppelnetoffset
	fd[NCONSTANTS.CFI_TIMESTAMPPREV] += doppelnetoffset
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_POSITION):
		if isframe0:
			fd[NCONSTANTS2.CFI_VRORIGIN_POSITION].z += -2
		else:
			fd.erase(NCONSTANTS2.CFI_VRORIGIN_POSITION)
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_ROTATION):
		fd[NCONSTANTS2.CFI_VRORIGIN_ROTATION] *= Quat(Vector3(0, 1, 0), deg2rad(180))

	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("OPP setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
