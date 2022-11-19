extends Spatial
class_name OpenXRallhandsdata

var specialist_openxr_gdns_script_loaded = false
var is_active_L = false
var is_active_R = false
var joint_transforms_L = [ ]
var joint_transforms_R = [ ]
var palm_joint_confidence_L = -1
var palm_joint_confidence_R = -1

var arvrorigin : ARVROrigin
var arcrconfigurationnode : Node
var arvrcontrollerleft : ARVRController
var arvrcontrollerright : ARVRController
var arvrcontroller3 : ARVRController
var arvrcontroller4 : ARVRController

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

enum {
	JOY_ID_HANDLEFT = 0, 
	JOY_ID_HANDRIGHT = 1, 
	JOY_ID_CONTROLLER_LEFT = 2, 
	JOY_ID_CONTROLLER_RIGHT = 3, 

	JOY_AXIS_THUMB_INDEX_PINCH = 7,
	JOY_AXIS_THUMB_MIDDLE_PINCH = 6,
	JOY_AXIS_THUMB_RING_PINCH = 2,
	JOY_AXIS_THUMB_LITTLE_PINCH = 4, 
	
	JOY_AXIS_THUMBSTICK_X = 0, 
	JOY_AXIS_THUMBSTICK_Y = 1, 
}

func setupopenxrpluginhandskeleton(handskelpose, aimpose, grippose, bright):
	if aimpose:
		aimpose.action = "godot/aim_pose"
		aimpose.path = "/user/hand/right" if bright else "/user/hand/left"
	if grippose:
		grippose.action = "godot/grip_pose"
		grippose.path = "/user/hand/right" if bright else "/user/hand/left"
		
	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRPose.cpp
	handskelpose.action = "SkeletonBase"
	handskelpose.path = "/user/hand/right" if bright else "/user/hand/left"

	# for these parameters see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRSkeleton.cpp
	var _LR = ("_R" if bright else "_L")
	var handskel = handskelpose.get_child(0)
	handskel.hand = 1 if bright else 0
	handskel.motion_range = XR_HAND_JOINTS_MOTION_RANGE_UNOBSTRUCTED_EXT
	for i in range(len(XRbone_names)):
		handskel.add_bone(XRbone_names[i] + _LR)
		if i >= 2:
			handskel.set_bone_parent(i, boneparentsToWrist[i])

func _enter_tree():
	specialist_openxr_gdns_script_loaded = ("path" in $LeftHandSkelPose)
	print("Handtrack enabled ", specialist_openxr_gdns_script_loaded, " ", $LeftHandSkelPose.get_script())
	assert (len(XRbone_names) == XR_HAND_JOINT_COUNT_EXT)
	assert (len(boneparentsToWrist) == XR_HAND_JOINT_COUNT_EXT)
	if specialist_openxr_gdns_script_loaded:
		setupopenxrpluginhandskeleton($LeftHandSkelPose, $LeftHandAimPose, $LeftHandGripPose, false)
		setupopenxrpluginhandskeleton($RightHandSkelPose, $RightHandAimPose, null, true)
		for i in range(XR_HAND_JOINT_COUNT_EXT):
			joint_transforms_L.push_back(Transform())
			joint_transforms_R.push_back(Transform())
	else:
		print("HAND TRACKING SYSTEM DISABLED")


func _ready():
	arvrorigin = get_parent()
	for child in arvrorigin.get_children():
		if child.is_class("ARVRController"):
			if child.controller_id == 1:
				arvrcontrollerleft = child
			elif child.controller_id == 2:
				arvrcontrollerright = child
			elif child.controller_id == 3:
				arvrcontroller3 = child
			elif child.controller_id == 4:
				arvrcontroller4 = child
				
		if child.get_script():
			if child.get_script().get_path() == "res://addons/godot-openxr/config/OpenXRConfig.gdns":
				arcrconfigurationnode = child
				
	set_physics_process(specialist_openxr_gdns_script_loaded)
	if arcrconfigurationnode and specialist_openxr_gdns_script_loaded:
		print("OpenXR extensions ", arcrconfigurationnode.get_enabled_extensions())
		#print("OpenXR action sets ", arcrconfigurationnode.get_action_sets())
	
#var tracking_confidence = configuration.get_tracking_confidence(controller_id)

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

var Dt = 0
func _physics_process(delta):
	is_active_L = $LeftHandSkelPose.is_active()
	if is_active_L:
		palm_joint_confidence_L = skel_backtoOXRjointtransforms(joint_transforms_L, $LeftHandSkelPose/LeftHandBlankSkeleton)
	else:
		palm_joint_confidence_L = TRACKING_CONFIDENCE_NOT_APPLICABLE

	is_active_R = $RightHandSkelPose.is_active()
	if is_active_R:
		palm_joint_confidence_R = skel_backtoOXRjointtransforms(joint_transforms_R, $RightHandSkelPose/RightHandBlankSkeleton) 
	else:
		palm_joint_confidence_R = TRACKING_CONFIDENCE_NOT_APPLICABLE

	Dt += delta
	if Dt > 0.5:
		Dt = 0
		# as from void XRExtHandTrackingExtensionWrapper::update_handtracking() 
		# these have the joystick settings
		print(arvrcontroller3.get_joystick_id(), "  ", arvrcontrollerleft.get_joystick_id(), "Rjoy ", arvrcontrollerright.get_joystick_axis(0), arvrcontrollerright.get_joystick_axis(1), " ", arvrcontroller4.get_joystick_axis(JOY_AXIS_THUMB_INDEX_PINCH), " ", arvrcontroller4.get_joystick_axis(JOY_AXIS_THUMB_INDEX_PINCH), 
		"  ", Input.get_joy_axis(3, JOY_AXIS_THUMB_INDEX_PINCH), 
		" ", Input.get_joy_axis(arvrcontroller3.get_joystick_id(), JOY_AXIS_THUMB_INDEX_PINCH), 
		" ", Input.get_joy_axis(arvrcontroller3.get_joystick_id(), JOY_AXIS_THUMB_MIDDLE_PINCH))

## Grip controller button
#export (XRTools.Axis) var pickup_axis_id = XRTools.Axis.VR_GRIP_AXIS
#export (XRTools.Buttons) var action_button_id = XRTools.Buttons.VR_TRIGGER

func _input(event):
	if event is InputEventJoypadButton:
		if event.pressed:
			print("joypad button ", event.button_index)
