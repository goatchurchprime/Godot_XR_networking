extends Spatial

# standard naming convention https://registry.khronos.org/OpenXR/specs/1.0/html/xrspec.html#_conventions_of_hand_joints
var XRbone_names = [ "Palm", "Wrist", "Thumb_Metacarpal", "Thumb_Proximal", "Thumb_Distal", "Thumb_Tip", "Index_Metacarpal", "Index_Proximal", "Index_Intermediate", "Index_Distal", "Index_Tip", "Middle_Metacarpal", "Middle_Proximal", "Middle_Intermediate", "Middle_Distal", "Middle_Tip", "Ring_Metacarpal", "Ring_Proximal", "Ring_Intermediate", "Ring_Distal", "Ring_Tip", "Little_Metacarpal", "Little_Proximal", "Little_Intermediate", "Little_Distal", "Little_Tip" ]
var boneparentsToWrist = [-1, -1, 1, 2, 3, 4, 1, 6, 7, 8, 9, 1, 11, 12, 13, 14, 1, 16, 17, 18, 19, 1, 21, 22, 23, 24]

var _handtracking_enabled = false
var is_active_L = false
var is_active_R = false
var joint_transforms_L = [ ]
var joint_transforms_R = [ ]
var palm_joint_confidence_L = -1
var palm_joint_confidence_R = -1

const XR_HAND_JOINT_COUNT_EXT = 26
const XR_HAND_JOINTS_MOTION_RANGE_UNOBSTRUCTED_EXT = 0
const TRACKING_CONFIDENCE_NOT_APPLICABLE = -1
const TRACKING_CONFIDENCE_NONE = 0
const TRACKING_CONFIDENCE_LOW = 1
const TRACKING_CONFIDENCE_HIGH = 2

func inithandposeskeletonparameters(handpalmpose, bright):
	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRPose.cpp
	handpalmpose.action = "SkeletonBase"
	handpalmpose.path = "/user/hand/right" if bright else "/user/hand/left"

	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRSkeleton.cpp
	var _LR = ("_R" if bright else "_L")
	var handskel = handpalmpose.get_child(0)
	handskel.hand = 1 if bright else 0
	handskel.motion_range = XR_HAND_JOINTS_MOTION_RANGE_UNOBSTRUCTED_EXT
	for i in range(len(XRbone_names)):
		handskel.add_bone(XRbone_names[i] + _LR)
		if i >= 2:
			handskel.set_bone_parent(i, boneparentsToWrist[i])

func _enter_tree():
	_handtracking_enabled = ("path" in $LeftHandPalmPose)
	print("Handtrack enabled ", _handtracking_enabled, " ", $LeftHandPalmPose.get_script())
	assert (len(XRbone_names) == XR_HAND_JOINT_COUNT_EXT)
	assert (len(boneparentsToWrist) == XR_HAND_JOINT_COUNT_EXT)
	if _handtracking_enabled:
		inithandposeskeletonparameters($LeftHandPalmPose, false)
		inithandposeskeletonparameters($RightHandPalmPose, true)
		for i in range(XR_HAND_JOINT_COUNT_EXT):
			joint_transforms_L.push_back(Transform())
			joint_transforms_R.push_back(Transform())
	else:
		print("HAND TRACKING SYSTEM DISABLED")

func _ready():
	set_physics_process(_handtracking_enabled)
		
func skel_backtoOXRjointtransforms(joint_transforms, skel):
	joint_transforms[0] = skel.get_parent().transform
	joint_transforms[1] = joint_transforms[0] * skel.get_bone_pose(1)
	for i in range(2, XR_HAND_JOINT_COUNT_EXT):
		var ip = boneparentsToWrist[i]
		joint_transforms[i] = joint_transforms[ip] * skel.get_bone_pose(i)
	return skel.get_parent().get_tracking_confidence()

func _physics_process(delta):
	is_active_L = $LeftHandPalmPose.is_active()
	if is_active_L:
		palm_joint_confidence_L = skel_backtoOXRjointtransforms(joint_transforms_L, $LeftHandPalmPose/LeftHandBlankSkeleton)
	else:
		palm_joint_confidence_L = TRACKING_CONFIDENCE_NOT_APPLICABLE
	is_active_R = $RightHandPalmPose.is_active()
	if is_active_R:
		palm_joint_confidence_R = skel_backtoOXRjointtransforms(joint_transforms_R, $RightHandPalmPose/RightHandBlankSkeleton)
	else:
		palm_joint_confidence_R = TRACKING_CONFIDENCE_NOT_APPLICABLE
	
