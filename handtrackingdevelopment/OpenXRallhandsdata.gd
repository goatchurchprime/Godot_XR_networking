extends Node3D
class_name OpenXRallhandsdata

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

var arvrorigin : XROrigin3D
var arvrheadcam : XRCamera3D
var arvrcontrollerleft : XRController3D
var arvrcontrollerright : XRController3D

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


func setupopenxrhandskeleton(openxrskel, LR, jointtransforms):
	assert (len(XRbone_names) == XR_HAND_JOINT_COUNT_EXT)
	assert (len(boneparentsToWrist) == XR_HAND_JOINT_COUNT_EXT)
	assert (openxrskel.get_bone_count() == 0)
	assert (len(jointtransforms) == 0)
	for i in range(len(XRbone_names)):
		var sl = XRbone_names[i] + "_" + LR
		openxrskel.add_bone(sl)
		openxrskel.set_bone_rest(i, valveboneresttransforms[sl])
		openxrskel.set_bone_pose_position(i, valveboneresttransforms[sl].origin)  # not set by the OpenXR plugin
		if i >= 2:
			openxrskel.set_bone_parent(i, boneparentsToWrist[i])
		jointtransforms.push_back(Transform3D())

func _enter_tree():
	setupopenxrhandskeleton($OpenXRHandLeft/LeftHandBlankSkeleton, "L", joint_transforms_L)
	setupopenxrhandskeleton($OpenXRHandRight/RightHandBlankSkeleton, "R", joint_transforms_R)

func _ready():
	if $knucklepositionsLeft.visible:
		while $knucklepositionsLeft.get_child_count() < XR_HAND_JOINT_COUNT_EXT:
			$knucklepositionsLeft.add_child($knucklepositionsLeft.get_child(0).duplicate())

	arvrorigin = XRHelpers.get_xr_origin(self)
	arvrcontrollerleft = XRHelpers.get_left_controller(self)
	arvrcontrollerright = XRHelpers.get_right_controller(self)
	arvrheadcam = XRHelpers.get_xr_camera(self)
	
<<<<<<< Updated upstream

		
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

=======
>>>>>>> Stashed changes
func OXRjointtransforms(joint_transforms, skel):
	joint_transforms[0] = skel.get_parent().transform
	joint_transforms[1] = joint_transforms[0] * skel.get_bone_pose(1)
	for i in range(2, XR_HAND_JOINT_COUNT_EXT):
		var ip = boneparentsToWrist[i]
		joint_transforms[i] = joint_transforms[ip] * skel.get_bone_pose(i)

func _process(delta):
	if $OpenXRHandLeft.visible:
		OXRjointtransforms(joint_transforms_L, $OpenXRHandLeft/LeftHandBlankSkeleton)
		palm_joint_confidence_L = TRACKING_CONFIDENCE_HIGH
		if $knucklepositionsLeft.visible:
			for i in range(min(XR_HAND_JOINT_COUNT_EXT, $knucklepositionsLeft.get_child_count())):
				$knucklepositionsLeft.get_child(i).transform.origin = joint_transforms_L[i].origin

	else:
		palm_joint_confidence_L = TRACKING_CONFIDENCE_NOT_APPLICABLE

	if $OpenXRHandRight.visible:
		OXRjointtransforms(joint_transforms_R, $OpenXRHandRight/RightHandBlankSkeleton)
		palm_joint_confidence_R = TRACKING_CONFIDENCE_HIGH
	else:
		palm_joint_confidence_R = TRACKING_CONFIDENCE_NOT_APPLICABLE

	controller_pose_confidence_L = arvrcontrollerleft.get_pose().tracking_confidence if arvrcontrollerleft.get_is_active() else TRACKING_CONFIDENCE_NOT_APPLICABLE
	controller_pose_confidence_R = arvrcontrollerright.get_pose().tracking_confidence if arvrcontrollerright.get_is_active() else TRACKING_CONFIDENCE_NOT_APPLICABLE
	controller_pose_transform_L = arvrcontrollerleft.transform
	controller_pose_transform_R = arvrcontrollerright.transform
	headcam_pose = arvrheadcam.transform


func gethandcontrollerpose(bright):
	if (pointer_pose_confidence_R if bright else pointer_pose_confidence_L) != TRACKING_CONFIDENCE_NOT_APPLICABLE:
		return (pointer_pose_transform_R if bright else pointer_pose_transform_L)
	if (palm_joint_confidence_R if bright else palm_joint_confidence_L) == TRACKING_CONFIDENCE_HIGH:
		return joint_transforms_R[XR_HAND_JOINT_WRIST_EXT] if bright else joint_transforms_L[XR_HAND_JOINT_WRIST_EXT]
	return null



const valveboneresttransforms = {
	"Palm_L":				Transform3D(Vector3(0.996362, -0.083606, 0.016515), Vector3(0.07856, 0.97618, 0.20224), Vector3(-0.03303, -0.200207, 0.979197), Vector3(0.00829, 0.009273, -0.051024)), 
	"Wrist_L":				Transform3D(Vector3(-0, 1, 0), Vector3(-1, -0, 0), Vector3(0, -0, 1), Vector3(-0.00016, -0.000032, 0.000626)), 
	"Thumb_Metacarpal_L":	Transform3D(Vector3(0.017728, -0.937347, 0.347948), Vector3(0.780952, 0.230287, 0.580588), Vector3(-0.62434, 0.261438, 0.736104), Vector3(0.029178, -0.017914, -0.025298)), 
	"Thumb_Proximal_L":		Transform3D(Vector3(0.999996, -0.000794, -0.002629), Vector3(-0.000558, 0.878596, -0.477565), Vector3(0.002689, 0.477565, 0.878592), Vector3(-0, 0, -0.040406)), 
	"Thumb_Distal_L":		Transform3D(Vector3(0.999996, 0.000237, 0.002802), Vector3(0.000623, 0.952976, -0.303043), Vector3(-0.002743, 0.303044, 0.952973), Vector3(-0, -0.000001, -0.032518)), 
	"Thumb_Tip_L":			Transform3D(Vector3(1, -0, 0), Vector3(0, 1, -0), Vector3(-0, 0, 1), Vector3(0, -0, -0.030462)), 
	"Index_Metacarpal_L":	Transform3D(Vector3(0.964214, -0.185985, 0.188946), Vector3(0.14633, 0.967611, 0.20571), Vector3(-0.221085, -0.1707, 0.9602), Vector3(0.021073, -0.001557, -0.014787)), 
	"Index_Proximal_L":		Transform3D(Vector3(0.994401, -0.02868, -0.101709), Vector3(-0.022388, 0.883443, -0.468003), Vector3(0.103277, 0.46766, 0.877854), Vector3(-0, 0, -0.073798)), 
	"Index_Intermediate_L":	Transform3D(Vector3(0.999949, 0.002032, 0.009878), Vector3(0.001694, 0.931726, -0.363158), Vector3(-0.009941, 0.363157, 0.931675), Vector3(0, 0.000001, -0.043285)), 
	"Index_Distal_L":		Transform3D(Vector3(0.999997, -0.000241, -0.00232), Vector3(-0.000116, 0.988309, -0.152468), Vector3(0.00233, 0.152468, 0.988306), Vector3(-0, 0, -0.028277)), 
	"Index_Tip_L":			Transform3D(Vector3(1, -0, -0.000001), Vector3(0, 1, -0), Vector3(0.000001, 0, 1), Vector3(-0, -0, -0.022822)), 
	"Middle_Metacarpal_L":	Transform3D(Vector3(0.996362, -0.083606, 0.016515), Vector3(0.07856, 0.97618, 0.20224), Vector3(-0.033031, -0.200206, 0.979197), Vector3(0.00712, 0.002177, -0.016319)), 
	"Middle_Proximal_L":	Transform3D(Vector3(1, -0.000085, -0.000361), Vector3(-0.000085, 0.894969, -0.446128), Vector3(0.000361, 0.446128, 0.894969), Vector3(-0, 0, -0.070885)), 
	"Middle_Intermediate_L":Transform3D(Vector3(0.999973, -0.001345, -0.007255), Vector3(-0.000977, 0.950453, -0.310866), Vector3(0.007314, 0.310865, 0.950426), Vector3(0, 0, -0.043108)), 
	"Middle_Distal_L":		Transform3D(Vector3(0.999966, 0.001378, 0.008138), Vector3(0.000953, 0.960082, -0.279717), Vector3(-0.008198, 0.279716, 0.960048), Vector3(-0, 0, -0.033266)), 
	"Middle_Tip_L":			Transform3D(Vector3(1, -0, -0), Vector3(0, 1, -0.000001), Vector3(0, 0.000001, 1), Vector3(-0, -0, -0.025892)), 
	"Ring_Metacarpal_L":	Transform3D(Vector3(0.99457, 0.039091, -0.096451), Vector3(-0.025077, 0.989484, 0.14245), Vector3(0.101005, -0.139257, 0.985092), Vector3(-0.006545, 0.000513, -0.016348)), 
	"Ring_Proximal_L":		Transform3D(Vector3(0.996643, -0.016295, -0.080227), Vector3(-0.019808, 0.902873, -0.429451), Vector3(0.079432, 0.429598, 0.89952), Vector3(-0, -0, -0.065974)), 
	"Ring_Intermediate_L":	Transform3D(Vector3(0.999987, 0.000822, 0.004998), Vector3(0.000533, 0.964179, -0.265252), Vector3(-0.005037, 0.265251, 0.964166), Vector3(0, 0, -0.040332)), 
	"Ring_Distal_L":		Transform3D(Vector3(0.999964, -0.001548, -0.008394), Vector3(-0.00076, 0.963358, -0.268218), Vector3(0.008501, 0.268214, 0.963322), Vector3(0, 0, -0.028491)), 
	"Ring_Tip_L":			Transform3D(Vector3(1, 0, -0), Vector3(-0, 1, 0), Vector3(0, -0, 1), Vector3(0, 0, -0.02243)), 
	"Little_Metacarpal_L":	Transform3D(Vector3(0.927157, 0.240122, -0.287613), Vector3(-0.22841, 0.970738, 0.074139), Vector3(0.296999, -0.003044, 0.954873), Vector3(-0.018981, -0.002478, -0.015214)), 
	"Little_Proximal_L":	Transform3D(Vector3(0.998382, -0.00162, 0.056831), Vector3(0.014046, 0.975633, -0.218957), Vector3(-0.055092, 0.219402, 0.974078), Vector3(0.000001, -0, -0.062855)), 
	"Little_Intermediate_L":Transform3D(Vector3(0.999737, -0.003795, -0.022607), Vector3(-0.002278, 0.964875, -0.2627), Vector3(0.02281, 0.262682, 0.964613), Vector3(-0, 0, -0.029875)), 
	"Little_Distal_L":		Transform3D(Vector3(0.999677, 0.003829, 0.025136), Vector3(0.001688, 0.976419, -0.215874), Vector3(-0.02537, 0.215847, 0.976097), Vector3(-0, -0.000001, -0.017978)), 
	"Little_Tip_L":			Transform3D(Vector3(1, 0, -0), Vector3(-0, 1, 0), Vector3(0, -0, 1), Vector3(-0, 0.000002, -0.018018)), 
	"Palm_R":				Transform3D(Vector3(0.996362, 0.083606, -0.016516), Vector3(-0.07856, 0.97618, 0.20224), Vector3(0.033031, -0.200207, 0.979197), Vector3(-0.00829, 0.009273, -0.051025)), 
	"Wrist_R":				Transform3D(Vector3(-0, 0, 1), Vector3(1, 0, 0), Vector3(-0, 1, -0), Vector3(0.00016, 0.000626, 0.000032)), 
	"Thumb_Metacarpal_R":	Transform3D(Vector3(0.017728, 0.937346, -0.347948), Vector3(-0.780951, 0.230287, 0.580588), Vector3(0.62434, 0.261438, 0.736104), Vector3(-0.029178, -0.017914, -0.025298)), 
	"Thumb_Proximal_R":		Transform3D(Vector3(0.999996, 0.000794, 0.002629), Vector3(0.000558, 0.878596, -0.477565), Vector3(-0.002689, 0.477564, 0.878592), Vector3(-0, 0, -0.040406)), 
	"Thumb_Distal_R":		Transform3D(Vector3(0.999996, -0.000237, -0.002803), Vector3(-0.000623, 0.952977, -0.303043), Vector3(0.002743, 0.303043, 0.952973), Vector3(0, 0, -0.032517)), 
	"Thumb_Tip_R":			Transform3D(Vector3(1, -0, -0), Vector3(0, 1, -0), Vector3(0, 0, 1), Vector3(-0.000001, -0.000001, -0.030464)), 
	"Index_Metacarpal_R":	Transform3D(Vector3(0.964214, 0.185985, -0.188946), Vector3(-0.14633, 0.967611, 0.20571), Vector3(0.221086, -0.1707, 0.960199), Vector3(-0.021073, -0.001557, -0.014787)), 
	"Index_Proximal_R":		Transform3D(Vector3(0.994401, 0.028681, 0.101709), Vector3(0.022388, 0.883443, -0.468003), Vector3(-0.103277, 0.46766, 0.877855), Vector3(0, 0, -0.073798)), 
	"Index_Intermediate_R":	Transform3D(Vector3(0.999949, -0.002032, -0.009877), Vector3(-0.001694, 0.931726, -0.363158), Vector3(0.009941, 0.363156, 0.931675), Vector3(0, -0, -0.043287)), 
	"Index_Distal_R":		Transform3D(Vector3(0.999997, 0.000241, 0.00232), Vector3(0.000116, 0.988308, -0.152468), Vector3(-0.00233, 0.152468, 0.988306), Vector3(0, -0, -0.028275)), 
	"Index_Tip_R":			Transform3D(Vector3(1, 0, -0), Vector3(-0, 1, 0), Vector3(0, -0, 1), Vector3(-0, -0, -0.022821)), 
	"Middle_Metacarpal_R":	Transform3D(Vector3(0.996362, 0.083606, -0.016516), Vector3(-0.07856, 0.97618, 0.20224), Vector3(0.033031, -0.200207, 0.979197), Vector3(-0.00712, 0.002177, -0.016319)), 
	"Middle_Proximal_R":	Transform3D(Vector3(1, 0.000085, 0.000361), Vector3(0.000085, 0.894969, -0.446128), Vector3(-0.000361, 0.446129, 0.894969), Vector3(0, -0, -0.070886)), 
	"Middle_Intermediate_R":Transform3D(Vector3(0.999972, 0.001345, 0.007255), Vector3(0.000977, 0.950453, -0.310866), Vector3(-0.007314, 0.310864, 0.950426), Vector3(-0, -0.000001, -0.043107)), 
	"Middle_Distal_R":		Transform3D(Vector3(0.999966, -0.001378, -0.008138), Vector3(-0.000953, 0.960082, -0.279718), Vector3(0.008198, 0.279716, 0.960048), Vector3(0, 0.000001, -0.033266)), 
	"Middle_Tip_R":			Transform3D(Vector3(1, -0, -0), Vector3(0, 1, -0), Vector3(0, 0, 1), Vector3(0, 0, -0.025892)), 
	"Ring_Metacarpal_R":	Transform3D(Vector3(0.99457, -0.039091, 0.096451), Vector3(0.025077, 0.989484, 0.14245), Vector3(-0.101005, -0.139257, 0.985092), Vector3(0.006545, 0.000513, -0.016348)), 
	"Ring_Proximal_R":		Transform3D(Vector3(0.996643, 0.016294, 0.080227), Vector3(0.019808, 0.902873, -0.429451), Vector3(-0.079432, 0.429598, 0.89952), Vector3(-0, -0, -0.065975)), 
	"Ring_Intermediate_R":	Transform3D(Vector3(0.999987, -0.000823, -0.004998), Vector3(-0.000533, 0.964179, -0.265251), Vector3(0.005037, 0.265251, 0.964166), Vector3(0, -0, -0.040331)), 
	"Ring_Distal_R":		Transform3D(Vector3(0.999964, 0.001548, 0.008394), Vector3(0.00076, 0.963358, -0.268218), Vector3(-0.008501, 0.268215, 0.963322), Vector3(0, 0, -0.02849)), 
	"Ring_Tip_R":			Transform3D(Vector3(1, -0, -0), Vector3(0, 1, 0.000001), Vector3(0, -0.000001, 1), Vector3(-0, -0.000002, -0.022428)), 
	"Little_Metacarpal_R":	Transform3D(Vector3(0.927157, -0.240122, 0.287613), Vector3(0.22841, 0.970738, 0.074139), Vector3(-0.296999, -0.003044, 0.954873), Vector3(0.018981, -0.002478, -0.015214)), 
	"Little_Proximal_R":	Transform3D(Vector3(0.998382, 0.00162, -0.056831), Vector3(-0.014047, 0.975633, -0.218957), Vector3(0.055092, 0.219401, 0.974078), Vector3(0, 0, -0.062855)), 
	"Little_Intermediate_R":Transform3D(Vector3(0.999737, 0.003795, 0.022607), Vector3(0.002278, 0.964875, -0.262699), Vector3(-0.02281, 0.262682, 0.964613), Vector3(0, -0, -0.029873)), 
	"Little_Distal_R":		Transform3D(Vector3(0.999677, -0.003829, -0.025136), Vector3(-0.001688, 0.97642, -0.215874), Vector3(0.02537, 0.215847, 0.976098), Vector3(-0, 0, -0.017978)), 
	"Little_Tip_R":			Transform3D(Vector3(1, 0, 0), Vector3(-0, 1, 0), Vector3(0, -0, 1), Vector3(-0, -0, -0.018018)) 
}
