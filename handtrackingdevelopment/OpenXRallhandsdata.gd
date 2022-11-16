extends Spatial
class_name OpenXRallhandsdata

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


func setupopenxrpluginhandskeleton(handpalmpose, bright):
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
		setupopenxrpluginhandskeleton($LeftHandPalmPose, false)
		setupopenxrpluginhandskeleton($RightHandPalmPose, true)
		for i in range(XR_HAND_JOINT_COUNT_EXT):
			joint_transforms_L.push_back(Transform())
			joint_transforms_R.push_back(Transform())
	else:
		print("HAND TRACKING SYSTEM DISABLED")

func _ready():
	set_physics_process(_handtracking_enabled)
		

static func Dcheckbonejointalignment(joint_transforms):
	for i in range(2, XR_HAND_JOINT_COUNT_EXT):
		var ip = boneparentsToWrist[i]
		var vp = joint_transforms[i].origin - joint_transforms[ip].origin
		if ip != XR_HAND_JOINT_WRIST_EXT or i == XR_HAND_JOINT_MIDDLE_METACARPAL_EXT:
			print(i, ",", ip, joint_transforms[ip].basis.inverse().xform(vp), joint_transforms[ip].basis.x.dot(vp))
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
		var ip = boneparentsToWrist[i]
		joint_transforms[i] = joint_transforms[ip] * skel.get_bone_pose(i)
	if joint_transforms[XR_HAND_JOINT_THUMB_PROXIMAL_EXT].origin == Vector3.ZERO:
		return TRACKING_CONFIDENCE_NONE
	return skel.get_parent().get_tracking_confidence()

func _physics_process(delta):
	is_active_L = $LeftHandPalmPose.is_active()
	is_active_R = $RightHandPalmPose.is_active()
	palm_joint_confidence_L = skel_backtoOXRjointtransforms(joint_transforms_L, $LeftHandPalmPose/LeftHandBlankSkeleton) if is_active_L else TRACKING_CONFIDENCE_NOT_APPLICABLE
	palm_joint_confidence_R = skel_backtoOXRjointtransforms(joint_transforms_R, $RightHandPalmPose/RightHandBlankSkeleton) if is_active_R else TRACKING_CONFIDENCE_NOT_APPLICABLE
