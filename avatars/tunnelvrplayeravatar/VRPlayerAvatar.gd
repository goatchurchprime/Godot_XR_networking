extends Node3D

@onready var arvrorigin = XRHelpers.get_xr_origin(get_node("/root/Main/XROrigin3D"))
var labeltext = "unknown"

@onready var LeftHandController = XRHelpers.get_left_controller(arvrorigin)
@onready var RightHandController = XRHelpers.get_right_controller(arvrorigin)
@onready var OpenXRHandLeft = arvrorigin.get_node_or_null("OpenXRHandLeft")
@onready var OpenXRHandRight = arvrorigin.get_node_or_null("OpenXRHandRight")


const TRACKING_CONFIDENCE_HIGH = 2
const TRACKING_CONFIDENCE_NOT_APPLICABLE = -1
const TRACKING_CONFIDENCE_NONE = 0

var joint_transforms_L = [ ]
var joint_transforms_R = [ ]

var ovrhandrightrestdata = null
var ovrhandleftrestdata = null

var shrinkavatartransform = Transform3D()

func _ready():
	ovrhandrightrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_right_hand_model)
	ovrhandleftrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_left_hand_model)
	var bluematerial = $HeadCam.material.duplicate()
	bluematerial.albedo_color = Color("#2876ea")
	$ovr_right_hand_model/ArmatureRight/Skeleton3D/r_handMeshNode.set_surface_override_material(0, bluematerial)	
	$ovr_left_hand_model/ArmatureLeft/Skeleton3D/l_handMeshNode.set_surface_override_material(0, bluematerial)
	
	for i in range(OpenXRInterface.HAND_JOINT_MAX):
		joint_transforms_L.push_back(Transform3D())
		joint_transforms_R.push_back(Transform3D())
		
func processavatarhand(palm_joint_confidence, joint_transforms, ovr_LR_hand_model, ovrhandLRrestdata, ControllerLR, LRHandController):
	if palm_joint_confidence != TRACKING_CONFIDENCE_NOT_APPLICABLE:
		ControllerLR.visible = false
		if palm_joint_confidence == TRACKING_CONFIDENCE_HIGH: 
			var ovrhandpose = OpenXRtrackedhand_funcs.setshapetobonesOVR(joint_transforms, ovrhandLRrestdata)
			ovr_LR_hand_model.transform = ovrhandpose["handtransform"]
			var skel = ovrhandLRrestdata["skel"]
			for i in ovrhandLRrestdata["boneindexes"]:
				if ovrhandpose.has(i):
					skel.set_bone_pose_rotation(i, Quaternion(ovrhandpose[i].basis))
					skel.set_bone_pose_position(i, ovrhandpose[i].origin)
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
	$HeadCam.transform = arvrorigin.get_node("XRCamera3D").transform
	var xr_interface = XRServer.primary_interface
	if xr_interface:
		var palm_joint_confidence_L = TRACKING_CONFIDENCE_HIGH if OpenXRHandLeft.visible else TRACKING_CONFIDENCE_NONE
		var palm_joint_confidence_R = TRACKING_CONFIDENCE_HIGH if OpenXRHandRight.visible else TRACKING_CONFIDENCE_NONE
		for i in range(OpenXRInterface.HAND_JOINT_MAX):
			joint_transforms_L[i] = Transform3D(Basis(xr_interface.get_hand_joint_rotation(0, i)), xr_interface.get_hand_joint_position(0, i))
			joint_transforms_R[i] = Transform3D(Basis(xr_interface.get_hand_joint_rotation(1, i)), xr_interface.get_hand_joint_position(1, i))
		processavatarhand(palm_joint_confidence_L, joint_transforms_L, $ovr_left_hand_model, ovrhandleftrestdata, $ControllerLeft, LeftHandController)
		processavatarhand(palm_joint_confidence_R, joint_transforms_R, $ovr_right_hand_model, ovrhandrightrestdata, $ControllerRight, RightHandController)

func setpaddlebody(active):
	$ControllerRight/PaddleBody.visible = active
	$ControllerRight/PaddleBody/CollisionShape3D.disabled = not active

func PAV_avatartoframedata():
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quaternion(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quaternion() 
			 }
			
	if $ovr_left_hand_model.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ovr_left_hand_model.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ovr_left_hand_model.transform.basis.get_rotation_quaternion()
		var skel = ovrhandleftrestdata["skel"]
		for i in ovrhandleftrestdata["boneindexes"]:
			fd[NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quaternion()
	elif $ControllerLeft.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ControllerLeft.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ControllerLeft.transform.basis.get_rotation_quaternion()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0

	if $ovr_right_hand_model.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $ovr_right_hand_model.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $ovr_right_hand_model.transform.basis.get_rotation_quaternion()
		var skel = ovrhandrightrestdata["skel"]
		for i in ovrhandrightrestdata["boneindexes"]:
			fd[NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quaternion()
	elif $ControllerRight.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $ControllerRight.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $ControllerRight.transform.basis.get_rotation_quaternion()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 0.0

	fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY] = $ControllerRight/PaddleBody.visible

	return fd

func overwritetransform(orgtransform, rot, pos):
	if rot == null:
		if pos == null:
			return orgtransform
		return Transform3D(orgtransform.basis, pos)
	if pos == null:
		return Transform3D(Basis(rot), orgtransform.origin)
	return Transform3D(Basis(rot), pos)

func PAV_framedatatoavatar(fd):
	transform = overwritetransform(transform, fd.get(NCONSTANTS2.CFI_VRORIGIN_ROTATION), fd.get(NCONSTANTS2.CFI_VRORIGIN_POSITION))
	$HeadCam.transform = overwritetransform($HeadCam.transform, fd.get(NCONSTANTS2.CFI_VRHEAD_ROTATION), fd.get(NCONSTANTS2.CFI_VRHEAD_POSITION))

	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE):
		var hcleftfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE)
		$ControllerLeft.visible = (hcleftfade > 0.0)
		$ovr_left_hand_model.visible = (hcleftfade < 0.0)
	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
		var hcrightfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE)
		$ControllerRight.visible = (hcrightfade > 0.0)
		$ovr_right_hand_model.visible = (hcrightfade < 0.0)
		
	if $ovr_left_hand_model.visible:
		$ovr_left_hand_model.transform = overwritetransform($ovr_left_hand_model.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
		var skel = $ovr_left_hand_model/ArmatureLeft/Skeleton3D
		for i in ovrhandleftrestdata["boneindexes"]:
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose_rotation(i, frot)
	elif $ControllerLeft.visible:
		$ControllerLeft.transform = overwritetransform($ControllerLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))

	if $ovr_right_hand_model.visible:
		$ovr_right_hand_model.transform = overwritetransform($ovr_right_hand_model.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))
		var skel = $ovr_right_hand_model/ArmatureRight/Skeleton3D
		for i in ovrhandrightrestdata["boneindexes"]:
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose_rotation(i, frot)
	elif $ControllerRight.visible:
		$ControllerRight.transform = overwritetransform($ControllerRight.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))

	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("remote setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
		setpaddlebody(fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])

		
var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func PAV_initavatarlocal():
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]
	$ovr_left_hand_model/ArmatureLeft/Skeleton3D/l_handMeshNode.set_surface_override_material(0, load("res://xrassets/vrhandmaterial.tres"))
	$ovr_right_hand_model/ArmatureRight/Skeleton3D/r_handMeshNode.set_surface_override_material(0, load("res://xrassets/vrhandmaterial.tres"))

func PAV_initavatarremote(avatardata):
	labeltext = avatardata["labeltext"]

func PAV_avatarinitdata():
	var avatardata = { "avatarsceneresource":get_scene_file_path(), 
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
		fd[NCONSTANTS2.CFI_VRORIGIN_ROTATION] *= Quaternion(Vector3(0, 1, 0), deg_to_rad(180))

	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("OPP setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])

