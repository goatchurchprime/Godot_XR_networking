extends Spatial

# standard naming convention https://registry.khronos.org/OpenXR/specs/1.0/html/xrspec.html#_conventions_of_hand_joints
var XRbone_names = [ "Palm", "Wrist", "Thumb_Metacarpal", "Thumb_Proximal", "Thumb_Distal", "Thumb_Tip", "Index_Metacarpal", "Index_Proximal", "Index_Intermediate", "Index_Distal", "Index_Tip", "Middle_Metacarpal", "Middle_Proximal", "Middle_Intermediate", "Middle_Distal", "Middle_Tip", "Ring_Metacarpal", "Ring_Proximal", "Ring_Intermediate", "Ring_Distal", "Ring_Tip", "Little_Metacarpal", "Little_Proximal", "Little_Intermediate", "Little_Distal", "Little_Tip" ]
var boneparentsToWrist = [-1, -1, 1, 2, 3, 4, 1, 6, 7, 8, 9, 1, 11, 12, 13, 14, 1, 16, 17, 18, 19, 1, 21, 22, 23, 24]

var _handtracking_enabled = false
var is_active_L = false
var is_active_R = false
var joint_transforms_L = [ ]
var joint_transforms_R = [ ]
var confidence_L = 0
var confidence_R = 0

const XR_HAND_JOINT_COUNT_EXT = 26

func inithandposeskeletonparameters(handpalmpose, bright):
	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRPose.cpp
	handpalmpose.action = "SkeletonBase"
	handpalmpose.path = "/user/hand/right" if bright else "/user/hand/left"

	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRSkeleton.cpp
	var _LR = ("_R" if bright else "_L")
	var handskel = handpalmpose.get_child(0)
	handskel.hand = 1 if bright else 0
	handskel.motion_range = 0
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

var Dt = 0.0
func _physics_process(delta):
	is_active_L = $LeftHandPalmPose.is_active()
	if is_active_L:
		confidence_L = skel_backtoOXRjointtransforms(joint_transforms_L, $LeftHandPalmPose/LeftHandBlankSkeleton)
	is_active_R = $RightHandPalmPose.is_active()
	if is_active_R:
		confidence_R = skel_backtoOXRjointtransforms(joint_transforms_R, $RightHandPalmPose/RightHandBlankSkeleton)
	
	Dt += delta
	if Dt > 1.0:
		print(is_active_L,is_active_R, " ", confidence_L, " ", confidence_R, " ", joint_transforms_L[25].origin)
		Dt = 0.0

# Notes:
#openxr_api->transform_from_location	calls
#TrackingConfidence _transform_from_location(const T &p_location, Transform &r_transform) {
# these are copying from the HandTracker.joint_locations[] array of class HandTracker 	
# this itself gets it from void XRExtHandTrackingExtensionWrapper::update_handtracking() {
# thi callout OS function is XrResult XRExtHandTrackingExtensionWrapper::initialise_ext_hand_tracking_extension(XrInstance instance) {

# once we apply the skel_tojointtransforms we get the original joint transforms 
# from the OpenXR library.  Then we can build up and apply to our 
# avatar rigs as we like, from the starting point.
# first thing is to analyse the rig to try and work out its hand orientations
# by the hook of the fingers, or some preset value

# func _ready():  sethand(false)
