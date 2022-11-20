extends Spatial


onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"

onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var OpenXRallhandsdata = arvrorigin.get_node("OpenXRallhandsdata")

var lowpolylefthandrestdata = null
var lowpolyrighthandrestdata = null

onready var gxtlefthandrestdata = OpenXRtrackedhand_funcs.getGXThandrestdata($LeftAppendage)
onready var gxtrighthandrestdata = OpenXRtrackedhand_funcs.getGXThandrestdata($RightAppendage)
var is_the_local_player = false

var shrinkavatartransform = Transform()

func _ready():
	assert ($FunctionPointer.active_button == XRTools.Buttons.VR_ACTION and $FunctionPointer.action == "")
	if is_the_local_player:
		OpenXRallhandsdata.connect("vr_button_action", self, "_on_vr_button")

var bright_active_pointer = false
var bactive_pointer_not_released = false
	
func _on_vr_button(button: int, bpressed: bool, bright: bool):
	if not bpressed:
		print("vr_buttonRelease ", button, " ", "R" if bright else "L")
	if button == XRTools.Buttons.VR_TRIGGER:
		if bright == bright_active_pointer:
			if bpressed:
				$FunctionPointer._on_button_pressed(XRTools.Buttons.VR_ACTION)
			elif bactive_pointer_not_released:
				$FunctionPointer._on_button_release(XRTools.Buttons.VR_ACTION)
			bactive_pointer_not_released = bpressed
		else:
			if bactive_pointer_not_released:
				$FunctionPointer._on_button_release(XRTools.Buttons.VR_ACTION)
				bactive_pointer_not_released = false
			bright_active_pointer = bright
	
	
	
func processavatarhand(LRAppendage, palm_joint_confidence, joint_transforms, gxthandrestdata, LRHandController, bright):
	var LRhand = LRAppendage.get_child(0)
	var LRcontroller = LRAppendage.get_child(1)
	
	if palm_joint_confidence != OpenXRallhandsdata.TRACKING_CONFIDENCE_NOT_APPLICABLE:
		LRcontroller.visible = false
		var h = OpenXRtrackedhand_funcs.gethandjointpositionsL(joint_transforms)
		if palm_joint_confidence == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH: 
			var lowpolyhandpose = OpenXRtrackedhand_funcs.setshapetobonesLowPoly(joint_transforms, gxthandrestdata, bright)
			LRAppendage.transform = lowpolyhandpose["handtransform"]
			var skel = gxthandrestdata["skel"]
			for i in range(25):
				skel.set_bone_pose(i, lowpolyhandpose[i])
			LRhand.visible = true
		else:
			LRhand.visible = false

	elif LRHandController.get_is_active():
		LRhand.visible = false
		LRAppendage.transform = LRHandController.transform
		LRcontroller.visible = true

	else:
		LRhand.visible = false
		LRcontroller.visible = false


func processpointer():
	$LeftPointerGripArea.transform = OpenXRallhandsdata.pointer_pose_transform_L
	$RightPointerGripArea.transform = OpenXRallhandsdata.pointer_pose_transform_R

	if (OpenXRallhandsdata.pointer_pose_confidence_R if bright_active_pointer else OpenXRallhandsdata.pointer_pose_confidence_L) == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH:
		$FunctionPointer.transform = OpenXRallhandsdata.pointer_pose_transform_R if bright_active_pointer else OpenXRallhandsdata.pointer_pose_transform_L
		var pinchedvalue = OpenXRallhandsdata.triggerpinchedjoyvalue_R if bright_active_pointer else OpenXRallhandsdata.triggerpinchedjoyvalue_L
		$FunctionPointer/IntensityMarker.scale = Vector3(1,pinchedvalue*2+0.5,1)
		if not $FunctionPointer.enabled:
			$FunctionPointer.set_enabled(true)
	elif $FunctionPointer.enabled:
		$FunctionPointer.set_enabled(false)

func PAV_processlocalavatarposition(delta):
	assert (is_the_local_player)
	transform = shrinkavatartransform*arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	processavatarhand($LeftAppendage, OpenXRallhandsdata.palm_joint_confidence_L, OpenXRallhandsdata.joint_transforms_L, gxtlefthandrestdata, LeftHandController, false)
	processavatarhand($RightAppendage, OpenXRallhandsdata.palm_joint_confidence_R, OpenXRallhandsdata.joint_transforms_R, gxtrighthandrestdata, RightHandController, true)
	processpointer()
		
#var controller_pose_transform_L : Transform = Transform()
#var controller_pose_transform_R : Transform = Transform()
#var controller_pose_confidence_L : int = TRACKING_CONFIDENCE_NOT_APPLICABLE
#var controller_pose_confidence_R : int = TRACKING_CONFIDENCE_NOT_APPLICABLE



func setpaddlebody(active):
	$RightAppendage/PaddleBody.visible = active
	$RightAppendage/PaddleBody/CollisionShape.disabled = not active

func PAV_avatartoframedata():
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quat() 
			 }
			
	var Lhand = $LeftAppendage.get_child(0)
	var Lcontroller = $LeftAppendage.get_child(1)
	var Rhand = $RightAppendage.get_child(0)
	var Rcontroller = $RightAppendage.get_child(1)

	if Lhand.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $LeftAppendage.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $LeftAppendage.transform.basis.get_rotation_quat()
		var skel = gxtlefthandrestdata["skel"]
		for i in range(25):
			fd[NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	elif Lcontroller.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION] = $LeftAppendage.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION] = $LeftAppendage.transform.basis.get_rotation_quat()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE] = 0.0

	if Rhand.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = -1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $RightAppendage.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $RightAppendage.transform.basis.get_rotation_quat()
		var skel = gxtrighthandrestdata["skel"]
		for i in range(25):
			fd[NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i] = skel.get_bone_pose(i).basis.get_rotation_quat()
	elif Rcontroller.visible:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 1.0
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION] = $RightAppendage.transform.origin
		fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION] = $RightAppendage.transform.basis.get_rotation_quat()
	else:
		fd[NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE] = 0.0

	fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY] = $RightAppendage/PaddleBody.visible

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

	var Lhand = $LeftAppendage.get_child(0)
	var Lcontroller = $LeftAppendage.get_child(1)
	var Rhand = $RightAppendage.get_child(0)
	var Rcontroller = $RightAppendage.get_child(1)

	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE):
		var hcleftfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERLEFT_FADE)
		Lcontroller.visible = (hcleftfade > 0.0)
		Lhand.visible = (hcleftfade < 0.0)
	if fd.has(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE):
		var hcrightfade = fd.get(NCONSTANTS2.CFI_VRHANDCONTROLLERRIGHT_FADE)
		Rcontroller.visible = (hcrightfade > 0.0)
		Rhand.visible = (hcrightfade < 0.0)
		
	if Lhand.visible or Lcontroller.visible:
		$LeftAppendage.transform = overwritetranform($LeftAppendage.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
		if Lhand.visible:
			var skel = Lhand.get_node("Armature/Skeleton")
			for i in range(25):
				var frot = fd.get(NCONSTANTS2.CFI_VRHANDLEFT_BONE_ROTATIONS+i)
				if frot != null:
					skel.set_bone_pose(i, Transform(frot))

	if Rhand.visible or Rcontroller.visible:
		$RightAppendage.transform = overwritetranform($RightAppendage.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))
		if Rhand.visible:
			var skel = Rhand.get_node("Armature/Skeleton")
			for i in range(25):
				var frot = fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_BONE_ROTATIONS+i)
				if frot != null:
					skel.set_bone_pose(i, Transform(frot))
	
	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		#print("remote setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
		setpaddlebody(fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])

	
var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func PAV_initavatarlocal():
	is_the_local_player = true
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]
	#$LeftHand/LeftHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))
	#$RightHand/RightHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))

func PAV_initavatarremote(avatardata):
	is_the_local_player = false
	labeltext = avatardata["labeltext"]
	#$LeftHand/LeftHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))
	#$RightHand/RightHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))

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
