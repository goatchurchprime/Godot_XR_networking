extends Spatial


onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"

onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var OpenXRallhandsdata = arvrorigin.get_node_or_null("OpenXRallhandsdata")

const TRACKING_CONFIDENCE_HIGH = 2

var ovrhandrightrestdata = null
var ovrhandleftrestdata = null

var shrinkavatartransform = Transform()

func _ready():
	ovrhandrightrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_right_hand_model)
	ovrhandleftrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_left_hand_model)
	
func processavatarhand(palm_joint_confidence, joint_transforms, ovr_LR_hand_model, ovrhandLRrestdata, ControllerLR, LRHandController):
	if palm_joint_confidence != -1:
		ControllerLR.visible = false
		if palm_joint_confidence == TRACKING_CONFIDENCE_HIGH: 
			var ovrhandpose = OpenXRtrackedhand_funcs.setshapetobonesOVR(joint_transforms, ovrhandLRrestdata)
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

func PAV_processlocalavatarposition(delta):
	transform = shrinkavatartransform*arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	processavatarhand(OpenXRallhandsdata.palm_joint_confidence_L, OpenXRallhandsdata.joint_transforms_L, $ovr_left_hand_model, ovrhandleftrestdata, $ControllerLeft, LeftHandController)
	processavatarhand(OpenXRallhandsdata.palm_joint_confidence_R, OpenXRallhandsdata.joint_transforms_R, $ovr_right_hand_model, ovrhandrightrestdata, $ControllerRight, RightHandController)

func setpaddlebody(active):
	$ControllerRight/PaddleBody.visible = active
	$ControllerRight/PaddleBody/CollisionShape.disabled = not active

func PAV_avatartoframedata():
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quat() 
			 }
			
	if $ovr_left_hand_model.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ovr_left_hand_model.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ovr_left_hand_model.transform.basis.get_rotation_quat()
		var skel = ovrhandleftrestdata["skel"]
		for i in range(23):
			fd[NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	elif $ControllerLeft.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ControllerLeft.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ControllerLeft.transform.basis.get_rotation_quat()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0

	if $ovr_right_hand_model.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $ovr_right_hand_model.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $ovr_right_hand_model.transform.basis.get_rotation_quat()
		var skel = ovrhandrightrestdata["skel"]
		for i in range(23):
			fd[NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	elif $ControllerRight.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $ControllerRight.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $ControllerRight.transform.basis.get_rotation_quat()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 0.0

	fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY] = $ControllerRight/PaddleBody.visible

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
	$HeadCam.transform = overwritetranform($HeadCam.transform, fd.get(NCONSTANTS2.CFI_VRHEAD_ROTATION), fd.get(NCONSTANTS2.CFI_VRHEAD_POSITION))

	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE):
		var hcleftfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE)
		$ControllerLeft.visible = (hcleftfade > 0.0)
		$ovr_left_hand_model.visible = (hcleftfade < 0.0)
	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
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
func PAV_initavatarlocal():
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]
	$ovr_left_hand_model/ArmatureLeft/Skeleton/l_handMeshNode.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))
	$ovr_right_hand_model/ArmatureRight/Skeleton/r_handMeshNode.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))

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

	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("OPP setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])