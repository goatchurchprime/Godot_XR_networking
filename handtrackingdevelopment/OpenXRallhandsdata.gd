extends Node3D
class_name OpenXRallhandsdata


signal vr_button_action(button, bpressed, bright)

var palm_joint_confidence_L = TRACKING_CONFIDENCE_NOT_APPLICABLE
var palm_joint_confidence_R = TRACKING_CONFIDENCE_NOT_APPLICABLE
var joint_transforms_L = [ ]
var joint_transforms_R = [ ]
var pointer_pose_transform_L : Transform3D = Transform3D()
var pointer_pose_transform_R : Transform3D = Transform3D()
var pointer_pose_confidence_L : int = TRACKING_CONFIDENCE_NOT_APPLICABLE
var pointer_pose_confidence_R : int = TRACKING_CONFIDENCE_NOT_APPLICABLE
var controller_pose_transform_L : Transform3D = Transform3D()
var controller_pose_transform_R : Transform3D = Transform3D()
var controller_pose_confidence_L : int = TRACKING_CONFIDENCE_NOT_APPLICABLE
var controller_pose_confidence_R : int = TRACKING_CONFIDENCE_NOT_APPLICABLE
var headcam_pose : Transform3D = Transform3D()

var triggerpinchedjoyvalue_L : float = 0.0
var triggerpinchedjoyvalue_R : float = 0.0
var grippinchedjoyvalue_L : float = 0.0
var grippinchedjoyvalue_R : float = 0.0


var arvrorigin : XROrigin3D
var arvrheadcam : XRCamera3D
var arvrconfigurationnode : Node
var arvrcontrollerleft : XRController3D
var arvrcontrollerright : XRController3D
var arvrcontroller3 : XRController3D
var arvrcontroller4 : XRController3D

const XR_HAND_JOINT_COUNT_EXT = 26
const XR_HAND_JOINTS_MOTION_RANGE_UNOBSTRUCTED_EXT = 0

enum {
	TRACKING_CONFIDENCE_NOT_APPLICABLE = -1,
	TRACKING_CONFIDENCE_NONE = 0,
	TRACKING_CONFIDENCE_LOW = 1,
	TRACKING_CONFIDENCE_HIGH = 2
}

# standard naming convention https://registry.khronos.org/OpenXR/specs/1.0/html/xrspec.html#_conventions_of_hand_joints
const XRbone_names = [ "Palm", "Wrist", "Thumb_Metacarpal", "Thumb_Proximal", "Thumb_Distal", "Thumb_Tip", "Index_Metacarpal", "Index_Proximal", "Index_Intermediate", "Index_Distal", "Index_Tip", "Middle_Metacarpal", "Middle_Proximal", "Middle_Intermediate", "Middle_Distal", "Middle_Tip", "Ring_Metacarpal", "Ring_Proximal", "Ring_Intermediate", "Ring_Distal", "Ring_Tip", "Little_Metacarpal", "Little_Proximal", "Little_Intermediate", "Little_Distal", "Little_Tip" ]
const boneparentsToWrist = [-1, -1, 1, 2, 3, 4, 1, 6, 7, 8, 9, 1, 11, 12, 13, 14, 1, 16, 17, 18, 19, 1, 21, 22, 23, 24]

enum {
	XR_HAND_JOINT_PALM_EXT = 0,
	XR_HAND_JOINT_WRIST_EXT = 1,
	XR_HAND_JOINT_THUMB_METACARPAL_EXT = 2,
	XR_HAND_JOINT_THUMB_PROXIMAL_EXT = 3,
	XR_HAND_JOINT_THUMB_DISTAL_EXT = 4,
	XR_HAND_JOINT_THUMB_TIP_EXT = 5,
	XR_HAND_JOINT_INDEX_METACARPAL_EXT = 6,
	XR_HAND_JOINT_INDEX_PROXIMAL_EXT = 7,
	XR_HAND_JOINT_INDEX_INTERMEDIATE_EXT = 8,
	XR_HAND_JOINT_INDEX_DISTAL_EXT = 9,
	XR_HAND_JOINT_INDEX_TIP_EXT = 10,
	XR_HAND_JOINT_MIDDLE_METACARPAL_EXT = 11,
	XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT = 12,
	XR_HAND_JOINT_MIDDLE_INTERMEDIATE_EXT = 13,
	XR_HAND_JOINT_MIDDLE_DISTAL_EXT = 14,
	XR_HAND_JOINT_MIDDLE_TIP_EXT = 15,
	XR_HAND_JOINT_RING_METACARPAL_EXT = 16,
	XR_HAND_JOINT_RING_PROXIMAL_EXT = 17,
	XR_HAND_JOINT_RING_INTERMEDIATE_EXT = 18,
	XR_HAND_JOINT_RING_DISTAL_EXT = 19,
	XR_HAND_JOINT_RING_TIP_EXT = 20,
	XR_HAND_JOINT_LITTLE_METACARPAL_EXT = 21,
	XR_HAND_JOINT_LITTLE_PROXIMAL_EXT = 22,
	XR_HAND_JOINT_LITTLE_INTERMEDIATE_EXT = 23,
	XR_HAND_JOINT_LITTLE_DISTAL_EXT = 24,
	XR_HAND_JOINT_LITTLE_TIP_EXT = 25
}

const xrfingers = [
	XR_HAND_JOINT_THUMB_PROXIMAL_EXT, XR_HAND_JOINT_THUMB_DISTAL_EXT, XR_HAND_JOINT_THUMB_TIP_EXT, 
	XR_HAND_JOINT_INDEX_PROXIMAL_EXT, XR_HAND_JOINT_INDEX_INTERMEDIATE_EXT, XR_HAND_JOINT_INDEX_DISTAL_EXT, XR_HAND_JOINT_INDEX_TIP_EXT, 
	XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT, XR_HAND_JOINT_MIDDLE_INTERMEDIATE_EXT, XR_HAND_JOINT_MIDDLE_DISTAL_EXT, XR_HAND_JOINT_MIDDLE_TIP_EXT, 
	XR_HAND_JOINT_RING_PROXIMAL_EXT, XR_HAND_JOINT_RING_INTERMEDIATE_EXT, XR_HAND_JOINT_RING_DISTAL_EXT, XR_HAND_JOINT_RING_TIP_EXT, 
	XR_HAND_JOINT_LITTLE_PROXIMAL_EXT, XR_HAND_JOINT_LITTLE_INTERMEDIATE_EXT, XR_HAND_JOINT_LITTLE_DISTAL_EXT, XR_HAND_JOINT_LITTLE_TIP_EXT 
]

const xrbones_necessary_to_measure_extent = [
	XR_HAND_JOINT_PALM_EXT, 
	XR_HAND_JOINT_THUMB_TIP_EXT, 
	XR_HAND_JOINT_INDEX_PROXIMAL_EXT, XR_HAND_JOINT_INDEX_TIP_EXT, 
	XR_HAND_JOINT_LITTLE_PROXIMAL_EXT, XR_HAND_JOINT_LITTLE_TIP_EXT 
]

enum {
	JOY_ID_CONTROLLER_LEFT = 2, 
	JOY_ID_CONTROLLER_RIGHT = 3, 
	JOY_ID_HANDLEFT = 0, 
	JOY_ID_HANDRIGHT = 1, 

	JOY_AXIS_THUMB_INDEX_PINCH = 7,   # VR_SECONDARY_Y_AXIS
	JOY_AXIS_THUMB_MIDDLE_PINCH = 6,  # VR_SECONDARY_X_AXIS
	JOY_AXIS_THUMB_RING_PINCH = 2,
	JOY_AXIS_THUMB_LITTLE_PINCH = 4, 
	
	JOY_AXIS_THUMBSTICK_X = 0, 
	JOY_AXIS_THUMBSTICK_Y = 1, 
	JOY_AXIS_TRIGGER_BUTTON = 2,
	JOY_AXIS_GRIP_BUTTON = 4,

	VR_BUTTON_THUMB_INDEX_PINCH = 7,  # VR_BUTTON_AX
	VR_BUTTON_THUMB_MIDDLE_PINCH = 1,
	VR_BUTTON_THUMB_RING_PINCH = 15,
	VR_BUTTON_THUMB_LITTLE_PINCH = 2,

	VR_BUTTON_TRIGGER = 15,
	VR_BUTTON_GRIP = 2,
	VR_BUTTON_TOUCH_AX = 5, 
	VR_BUTTON_AX = 7, 
	VR_BUTTON_TOUCH_BY = 6,
	VR_BUTTON_BY = 1,
	VR_BUTTON_TOUCH_PAD = 12,
	VR_BUTTON_PAD = 14,
	VR_BUTTON_THUMB_INDEX_PINCH_VIA_CONTROLLER_SIGNAL = 4,
}


func setupopenxrpluginhandskeleton(handskelpose, _LR):
	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRPose.cpp
	handskelpose.action = "SkeletonBase"
	handskelpose.path = "/user/hand/right" if _LR == "_R" else "/user/hand/left"

	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRSkeleton.cpp
	assert (len(XRbone_names) == XR_HAND_JOINT_COUNT_EXT)
	assert (len(boneparentsToWrist) == XR_HAND_JOINT_COUNT_EXT)
	var handskel = handskelpose.get_child(0)
	handskel.hand = 1 if _LR == "_R" else 0
	handskel.motion_range = XR_HAND_JOINTS_MOTION_RANGE_UNOBSTRUCTED_EXT
	for i in range(len(XRbone_names)):
		handskel.add_bone(XRbone_names[i] + _LR)
		if i >= 2:
			handskel.set_bone_parent(i, boneparentsToWrist[i])


func setupopenxrhandskeleton(openxrhand, _LR, valveskel):
	assert (len(XRbone_names) == XR_HAND_JOINT_COUNT_EXT)
	assert (len(boneparentsToWrist) == XR_HAND_JOINT_COUNT_EXT)
	var handskel = openxrhand.get_child(0)
	if valveskel != null:
		valveskel.get_parent().remove_child(valveskel)
		openxrhand.remove_child(handskel)
		valveskel.set_name(handskel.get_name())
		openxrhand.add_child(valveskel)
		handskel = valveskel
	else:
		for i in range(len(XRbone_names)):
			handskel.add_bone(XRbone_names[i] + _LR)
			handskel.set_bone_rest(i, Transform3D(Basis(), Vector3(0.0, 0.0, -0.1)))
			handskel.set_bone_pose_position(i, Vector3(0.0, 0.0, -0.1))
			if i >= 2:
				handskel.set_bone_parent(i, boneparentsToWrist[i])
	print(handskel.get_bone_rest(7))
	print(handskel.get_bone_pose(11))
	openxrhand.set_hand_skeleton(NodePath(handskel.get_name()))
	

func _enter_tree():
	setupopenxrhandskeleton($OpenXRHandLeft, "_L", $ValveLeftHandModel/Armature_001/Skeleton3D)
	setupopenxrhandskeleton($OpenXRHandRight, "_R", $ValveRightHandModel/Armature/Skeleton3D)
	for i in range(XR_HAND_JOINT_COUNT_EXT):
		joint_transforms_L.push_back(Transform3D())
		joint_transforms_R.push_back(Transform3D())

func _ready():
	arvrorigin = get_parent()
	for child in arvrorigin.get_children():
		if child.is_class("XRController3D"):
			if child.tracker == "left_hand":
				arvrcontrollerleft = child
			elif child.tracker == "right_hand":
				arvrcontrollerright = child
		if child.is_class("XRCamera3D"):
			arvrheadcam = child
		if child.get_script():
			if child.get_script().get_path() == "res://addons/godot-openxr/config/OpenXRConfig.gdns":
				arvrconfigurationnode = child
				
	

static func Dcheckbonejointalignment(joint_transforms):
	for i in range(2, XR_HAND_JOINT_COUNT_EXT):
		var ip = boneparentsToWrist[i]
		var vp = joint_transforms[i].origin - joint_transforms[ip].origin
		if ip != XR_HAND_JOINT_WRIST_EXT or i == XR_HAND_JOINT_MIDDLE_METACARPAL_EXT:
			print(i, ",", ip, joint_transforms[ip].basis.inverse() * (vp), joint_transforms[ip].basis.x.dot(vp))
	var Dpalmpos = 0.5*(joint_transforms[XR_HAND_JOINT_MIDDLE_METACARPAL_EXT].origin + joint_transforms[XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT].origin)
	#var ta = joint_transforms[XR_HAND_JOINT_MIDDLE_METACARPAL_EXT].origin
	var ta = joint_transforms[XR_HAND_JOINT_WRIST_EXT].origin
	var tb = joint_transforms[XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT].origin
	var tp = joint_transforms[XR_HAND_JOINT_PALM_EXT].origin
	var vab = tb - ta
	var tlam = (tp - ta).dot(vab)/vab.length_squared()
	print("palm ", Dpalmpos - joint_transforms[XR_HAND_JOINT_PALM_EXT].origin)
	print("Dpalm lam ", tlam, " perp ", (ta + vab*tlam - tp).length()) # joint_transforms[XR_HAND_JOINT_PALM_EXT].origin, joint_transforms[XR_HAND_JOINT_MIDDLE_METACARPAL_EXT].origin, joint_transforms[XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT].origin)
	print("tpalm ", joint_transforms[XR_HAND_JOINT_PALM_EXT].basis.z.cross(joint_transforms[XR_HAND_JOINT_MIDDLE_METACARPAL_EXT].basis.z))
	if 0:   # test tips bases are same as previous bone
		for itip in [ XR_HAND_JOINT_THUMB_TIP_EXT, XR_HAND_JOINT_INDEX_TIP_EXT, XR_HAND_JOINT_MIDDLE_TIP_EXT, XR_HAND_JOINT_MIDDLE_TIP_EXT, XR_HAND_JOINT_RING_TIP_EXT, XR_HAND_JOINT_LITTLE_TIP_EXT]:
			var iptip = boneparentsToWrist[itip]
			print("tip", itip, joint_transforms[itip].basis.inverse()*joint_transforms[iptip].basis)

		
func skel_backtoOXRjointtransforms(joint_transforms, skel):
	joint_transforms[0] = skel.get_parent().transform
	joint_transforms[1] = joint_transforms[0] * skel.get_bone_pose(1)
	for i in range(2, XR_HAND_JOINT_COUNT_EXT):
		#var ip = boneparentsToWrist[i]   # wrong by one, wrist wrong place
		var ip = skel.get_bone_parent(i)
		joint_transforms[i] = joint_transforms[ip] * skel.get_bone_pose(i)

	# reshuffle around to it is as expected by the subsequent code where the palm was number 1
	var jwrist = joint_transforms[XR_HAND_JOINT_COUNT_EXT-1]
	for i in range(XR_HAND_JOINT_COUNT_EXT-1, -1, -1):
		joint_transforms[i] = joint_transforms[i-1]
	joint_transforms[0] = jwrist


	if joint_transforms[XR_HAND_JOINT_THUMB_PROXIMAL_EXT].origin == Vector3.ZERO:
		return TRACKING_CONFIDENCE_NONE
	return TRACKING_CONFIDENCE_HIGH
	#return skel.get_parent().get_tracking_confidence()



var Dt = 0
func _physics_process(delta):
	controller_pose_confidence_L = arvrcontrollerleft.get_pose().tracking_confidence if arvrcontrollerleft.get_is_active() else TRACKING_CONFIDENCE_NOT_APPLICABLE
	controller_pose_confidence_R = arvrcontrollerright.get_pose().tracking_confidence if arvrcontrollerright.get_is_active() else TRACKING_CONFIDENCE_NOT_APPLICABLE
	controller_pose_transform_L = arvrcontrollerleft.transform
	controller_pose_transform_R = arvrcontrollerright.transform
	headcam_pose = arvrheadcam.transform

	palm_joint_confidence_L = skel_backtoOXRjointtransforms(joint_transforms_L, $OpenXRHandLeft/LeftHandBlankSkeleton) \
			if $OpenXRHandLeft.visible else TRACKING_CONFIDENCE_NOT_APPLICABLE
	palm_joint_confidence_R = skel_backtoOXRjointtransforms(joint_transforms_R, $OpenXRHandRight/RightHandBlankSkeleton) \
			if $OpenXRHandRight.visible else TRACKING_CONFIDENCE_NOT_APPLICABLE

#	triggerpinchedjoyvalue_L = (arvrcontroller3.get_joystick_axis(JOY_AXIS_THUMB_INDEX_PINCH)+1)/2 if arvrcontroller3.get_joystick_id() != -1 else arvrcontrollerleft.get_joystick_axis(JOY_AXIS_TRIGGER_BUTTON)
#	triggerpinchedjoyvalue_R = (arvrcontroller4.get_joystick_axis(JOY_AXIS_THUMB_INDEX_PINCH)+1)/2 if arvrcontroller4.get_joystick_id() != -1 else arvrcontrollerright.get_joystick_axis(JOY_AXIS_TRIGGER_BUTTON)
	#grippinchedjoyvalue_L = (arvrcontroller3.get_joystick_axis(JOY_AXIS_THUMB_MIDDLE_PINCH)+1)/2 if arvrcontroller3.get_joystick_id() != -1 else arvrcontrollerleft.get_joystick_axis(JOY_AXIS_GRIP_BUTTON)
	#grippinchedjoyvalue_R = (arvrcontroller4.get_joystick_axis(JOY_AXIS_THUMB_MIDDLE_PINCH)+1)/2 if arvrcontroller4.get_joystick_id() != -1 else arvrcontrollerright.get_joystick_axis(JOY_AXIS_GRIP_BUTTON)
	
	Dt += delta
	if Dt > 2.0:
		Dt = 0
		#print()
		#print(joint_transforms_R[7])
		#print(joint_transforms_R[11])
		#print($OpenXRHandRight/RightHandBlankSkeleton.get_bone_pose(7))
#		print("palm confidence ", palm_joint_confidence_L, "  ", palm_joint_confidence_R)
		# as from void XRExtHandTrackingExtensionWrapper::update_handtracking() 
		# these have the joystick settings
#		print(arvrcontrollerleft.get_joystick_id(),",", arvrcontroller3.get_joystick_id(), "  ", arvrcontrollerleft.get_joystick_id(), "Rjoy ", arvrcontrollerright.get_joystick_axis(2), arvrcontrollerright.get_joystick_axis(3), " ", arvrcontrollerright.get_joystick_axis(4), " ", arvrcontroller4.get_joystick_axis(JOY_AXIS_THUMB_INDEX_PINCH), 
#			"  ", Input.get_joy_axis(3, int(JOY_AXIS_THUMB_INDEX_PINCH)), 
#			" ", Input.get_joy_axis(arvrcontroller3.get_joystick_id(), int(JOY_AXIS_THUMB_INDEX_PINCH)), 
#			" ", Input.get_joy_axis(arvrcontroller3.get_joystick_id(), int(JOY_AXIS_THUMB_MIDDLE_PINCH)))

func gethandcontrollerpose(bright):
	if (pointer_pose_confidence_R if bright else pointer_pose_confidence_L) != TRACKING_CONFIDENCE_NOT_APPLICABLE:
		return (pointer_pose_transform_R if bright else pointer_pose_transform_L)
	if (palm_joint_confidence_R if bright else palm_joint_confidence_L) == TRACKING_CONFIDENCE_HIGH:
		return joint_transforms_R[XR_HAND_JOINT_WRIST_EXT] if bright else joint_transforms_L[XR_HAND_JOINT_WRIST_EXT]
	return null
