extends Node3D

@onready var arvrorigin = XRHelpers.get_xr_origin(get_node("/root/Main/XROrigin3D"))
var labeltext = "unknown"

@onready var LeftHandController = XRHelpers.get_left_controller(arvrorigin)
@onready var RightHandController = XRHelpers.get_right_controller(arvrorigin)
@onready var OpenXRHandLeft = arvrorigin.get_node_or_null("OpenXRHandLeft")
@onready var OpenXRHandRight = arvrorigin.get_node_or_null("OpenXRHandRight")

var clientawaitingspawnpoint = false
var nextframeisfirst = false

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
		

var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func PF_initlocalplayer():
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]
	$ovr_left_hand_model/ArmatureLeft/Skeleton3D/l_handMeshNode.set_surface_override_material(0, load("res://xrassets/vrhandmaterial.tres"))
	$ovr_right_hand_model/ArmatureRight/Skeleton3D/r_handMeshNode.set_surface_override_material(0, load("res://xrassets/vrhandmaterial.tres"))

func PF_connectedtoserver():
	if not multiplayer.is_server():
		clientawaitingspawnpoint = true

func spawnpointfornewplayer():
	var sfd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				 NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quaternion()
			  }
	sfd[NCONSTANTS2.CFI_VRORIGIN_ROTATION] *= Quaternion(Vector3(0,1,0), deg_to_rad(45))
	sfd[NCONSTANTS2.CFI_VRORIGIN_POSITION] += Vector3(1,0,-1.5)
	return sfd

func spawnpointreceivedfromserver(sfd):
	print("** spawnpointreceivedfromserver", sfd)
	arvrorigin.transform = Transform3D(Basis(sfd[NCONSTANTS2.CFI_VRORIGIN_ROTATION]), sfd[NCONSTANTS2.CFI_VRORIGIN_POSITION])
	clientawaitingspawnpoint = false
	nextframeisfirst = true

func PF_datafornewconnectedplayer():
	var avatardata = { "avatarsceneresource":get_scene_file_path(), 
					   "labeltext":labeltext
					 }
	if multiplayer.is_server():
		avatardata["spawnframedata"] = spawnpointfornewplayer()

	# if we are already spawned then we should send our position
	if not clientawaitingspawnpoint:
		avatardata["framedata0"] = get_node("PlayerFrame").framedata0.duplicate()
		avatardata["framedata0"].erase(NCONSTANTS.CFI_TIMESTAMP_F0)

	return avatardata

func PF_startupdatafromconnectedplayer(avatardata, localplayer):
	labeltext = avatardata["labeltext"]
	if "framedata0" in avatardata:
		get_node("PlayerFrame").networkedavatarthinnedframedata(avatardata["framedata0"])
	else:
		visible = false
	if "spawnframedata" in avatardata:
		localplayer.spawnpointreceivedfromserver(avatardata["spawnframedata"])


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


func skelbonescopy(skela, skelb):
	for i in range(skela.get_bone_count()):
		skela.set_bone_pose_rotation(i, skelb.get_bone_pose_rotation(i))

func PF_processlocalavatarposition(delta):
	if clientawaitingspawnpoint:
		return false
	transform = shrinkavatartransform*arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("XRCamera3D").transform
	$hand_l.transform = arvrorigin.global_transform.inverse()*arvrorigin.get_node("LeftHandController/LeftHand/Hand_Glove_low_L").global_transform
	skelbonescopy($hand_l/Armature/Skeleton3D, arvrorigin.get_node("LeftHandController/LeftHand/Hand_Glove_low_L/Armature/Skeleton3D"))
	$hand_r.transform = arvrorigin.global_transform.inverse()*arvrorigin.get_node("RightHandController/RightHand/Hand_low_R").global_transform
	skelbonescopy($hand_r/Armature/Skeleton3D, arvrorigin.get_node("RightHandController/RightHand/Hand_low_R/Armature/Skeleton3D"))
	if clientawaitingspawnpoint:
		return false
	return true

func setpaddlebody(active):
	$ControllerRight/PaddleBody.visible = active
	$ControllerRight/PaddleBody/CollisionShape3D.disabled = not active

func PF_avatartoframedata():
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quaternion(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quaternion(), 
				NCONSTANTS.CFI_VISIBLE: visible 
			 }
	if $hand_l.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $hand_l.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $hand_l.transform.basis.get_rotation_quaternion()
		var skel = $hand_l/Armature/Skeleton3D
		for i in range(skel.get_bone_count()):
			fd[NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i] = skel.get_bone_pose_rotation(i)
	elif $ControllerLeft.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ControllerLeft.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ControllerLeft.transform.basis.get_rotation_quaternion()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0

	if $hand_r.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $hand_r.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $hand_r.transform.basis.get_rotation_quaternion()
		var skel = $hand_r/Armature/Skeleton3D
		for i in range(skel.get_bone_count()):
			fd[NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i] = skel.get_bone_pose_rotation(i)
	elif $ControllerRight.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $ControllerRight.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $ControllerRight.transform.basis.get_rotation_quaternion()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 0.0

	fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY] = $ControllerRight/PaddleBody.visible
	if nextframeisfirst:
		fd[NCONSTANTS.CFI_NOTHINFRAME] = 1
		nextframeisfirst = false

	return fd

func overwritetransform(orgtransform, rot, pos):
	if rot == null:
		if pos == null:
			return orgtransform
		return Transform3D(orgtransform.basis, pos)
	if pos == null:
		return Transform3D(Basis(rot), orgtransform.origin)
	return Transform3D(Basis(rot), pos)

func PF_framedatatoavatar(fd):
	transform = overwritetransform(transform, fd.get(NCONSTANTS2.CFI_VRORIGIN_ROTATION), fd.get(NCONSTANTS2.CFI_VRORIGIN_POSITION))
	$HeadCam.transform = overwritetransform($HeadCam.transform, fd.get(NCONSTANTS2.CFI_VRHEAD_ROTATION), fd.get(NCONSTANTS2.CFI_VRHEAD_POSITION))
	if fd.has(NCONSTANTS.CFI_VISIBLE):
		visible = fd[NCONSTANTS.CFI_VISIBLE]

	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE):
		var hcleftfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE)
		$ControllerLeft.visible = (hcleftfade > 0.0)
		$ovr_left_hand_model.visible = (hcleftfade < 0.0)
	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
		var hcrightfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE)
		$ControllerRight.visible = (hcrightfade > 0.0)
		$ovr_right_hand_model.visible = (hcrightfade < 0.0)
		
	if $hand_l.visible:
		$hand_l.transform = overwritetransform($hand_l.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
		var skel = $hand_l/Armature/Skeleton3D
		for i in range(skel.get_bone_count()):
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose_rotation(i, frot)

	elif $ovr_left_hand_model.visible:
		$ovr_left_hand_model.transform = overwritetransform($ovr_left_hand_model.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
		var skel = $ovr_left_hand_model/ArmatureLeft/Skeleton3D
		for i in ovrhandleftrestdata["boneindexes"]:
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose_rotation(i, frot)
	elif $ControllerLeft.visible:
		$ControllerLeft.transform = overwritetransform($ControllerLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))

	if $hand_r.visible:
		$hand_r.transform = overwritetransform($hand_r.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))
		var skel = $hand_r/Armature/Skeleton3D
		for i in range(skel.get_bone_count()):
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose_rotation(i, frot)

	elif $ovr_right_hand_model.visible:
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

	

static func PF_changethinnedframedatafordoppelganger(fd, doppelnetoffset, isframe0):
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

