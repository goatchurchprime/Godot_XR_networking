extends Spatial


onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"

onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var OpenXRallhandsdata = arvrorigin.get_node_or_null("OpenXRallhandsdata")

const TRACKING_CONFIDENCE_HIGH = 2

var lowpolylefthandrestdata = null
var lowpolyrighthandrestdata = null

var shrinkavatartransform = Transform()

func _ready():
	lowpolyrighthandrestdata = OpenXRtrackedhand_funcs.getlowpolyhandrestdata($RightHand)
	lowpolylefthandrestdata = OpenXRtrackedhand_funcs.getlowpolyhandrestdata($LeftHand)
	assert ($LeftHand.get_script() == null)
	assert ($RightHand.get_script() == null)
	assert (not $LeftHand/AnimationTree.active and not $RightHand/AnimationTree.active)
	
func processavatarhand(palm_joint_confidence, joint_transforms, LRHand, lowpolyhandrestdata, ControllerLR, LRHandController, bright):
	if palm_joint_confidence != -1:
		ControllerLR.visible = false
		var h = OpenXRtrackedhand_funcs.gethandjointpositionsL(joint_transforms)
		if palm_joint_confidence == TRACKING_CONFIDENCE_HIGH: 
			var lowpolyhandpose = OpenXRtrackedhand_funcs.setshapetobonesLowPoly(joint_transforms, lowpolyhandrestdata, bright)
			LRHand.transform = lowpolyhandpose["handtransform"]
			var skel = lowpolyhandrestdata["skel"]
			for i in range(20):
				skel.set_bone_pose(i, lowpolyhandpose[i])
			LRHand.visible = true
		else:
			LRHand.visible = false

	elif LRHandController.get_is_active():
		LRHand.visible = false
		ControllerLR.transform = LRHandController.transform
		ControllerLR.visible = true
	else:
		LRHand.visible = false
		ControllerLR.visible = false

func PAV_processlocalavatarposition(delta):
	transform = shrinkavatartransform*arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	processavatarhand(OpenXRallhandsdata.palm_joint_confidence_L, OpenXRallhandsdata.joint_transforms_L, $LeftHand, lowpolylefthandrestdata, $ControllerLeft, LeftHandController, false)
	processavatarhand(OpenXRallhandsdata.palm_joint_confidence_R, OpenXRallhandsdata.joint_transforms_R, $RightHand, lowpolyrighthandrestdata, $ControllerRight, RightHandController, true)

func setpaddlebody(active):
	$ControllerRight/PaddleBody.visible = active
	$ControllerRight/PaddleBody/CollisionShape.disabled = not active

func PAV_avatartoframedata():
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quat() 
			 }
			
	if $LeftHand.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $LeftHand.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $LeftHand.transform.basis.get_rotation_quat()
		var skel = lowpolylefthandrestdata["skel"]
		for i in range(23):
			fd[NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	elif $ControllerLeft.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $ControllerLeft.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $ControllerLeft.transform.basis.get_rotation_quat()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0

	if $RightHand.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $RightHand.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $RightHand.transform.basis.get_rotation_quat()
		var skel = lowpolyrighthandrestdata["skel"]
		for i in range(20):
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
		$LeftHand.visible = (hcleftfade < 0.0)
	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
		var hcrightfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE)
		$ControllerRight.visible = (hcrightfade > 0.0)
		$LeftHand.visible = (hcrightfade < 0.0)
		
	if $LeftHand.visible:
		$LeftHand.transform = overwritetranform($LeftHand.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
		var skel = $LeftHand/LeftHand/Armature_Left/Skeleton
		for i in range(20):
			var frot = fd.get(NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i)
			if frot != null:
				skel.set_bone_pose(i, Transform(frot))
	elif $ControllerLeft.visible:
		$ControllerLeft.transform = overwritetranform($ControllerLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))

	if $RightHand.visible:
		$RightHand.transform = overwritetranform($RightHand.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))
		var skel = $RightHand/RightHand/Armature_Left/Skeleton
		for i in range(20):
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
	$LeftHand/LeftHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))
	$RightHand/RightHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))

func PAV_initavatarremote(avatardata):
	labeltext = avatardata["labeltext"]
	$LeftHand/LeftHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))
	$RightHand/RightHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))

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
