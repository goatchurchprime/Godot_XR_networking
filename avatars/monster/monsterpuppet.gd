extends Node3D

@onready var mskel = $Monster/Origin/MonsterArmature/Skeleton3D
@onready var aplayer = $Monster/Origin/AnimationPlayer
@onready var OpenXRallhandsdata = get_node("../FPController/OpenXRallhandsdata")

@onready var forearm_r = mskel.find_bone("forearm .R")         # 7
@onready var hand_r = mskel.find_bone("hand .R")               # 28
@onready var hand_r_control = mskel.get_bone_parent(hand_r)   # 27 arm_control_r

@onready var forearm_l = mskel.find_bone("forearm .L")         # 6
@onready var hand_l = mskel.find_bone("hand .L")               # 21
@onready var hand_l_control = mskel.get_bone_parent(hand_l)   # 20 arm_control_l
@onready var pelvis = mskel.find_bone("pelvis")               # 0
@onready var chest = mskel.find_bone("chest")                 # 1
@onready var neck = mskel.find_bone("neck")                   # 2
@onready var head = mskel.find_bone("head")                   # 3
@onready var headrestpose = mskel.get_bone_global_pose(head)

@onready var roty180 = Transform3D(Vector3(-1,0,0), Vector3(0,1,0), Vector3(0,0,-1),  Vector3(0,0,0))
@onready var mskel_bonerest_handcontrolR = roty180*mskel.get_bone_rest(hand_r_control)
@onready var mskel_bonerest_handcontrolR_inverse = mskel_bonerest_handcontrolR.inverse()
@onready var mskel_bonerest_handcontrolL = roty180*mskel.get_bone_rest(hand_r_control)
@onready var mskel_bonerest_handcontrolL_inverse = mskel_bonerest_handcontrolL.inverse()

func _ready():
	aplayer.play("throw")
	assert (forearm_r != -1 and forearm_l != -1)
	assert (hand_r != -1 and hand_l != -1)
	assert (pelvis != -1 and chest != -1 and neck != -1 and head != -1)

var Dt = 0
@onready var dinoscale = 1.0/$Monster.scale.x

# Called when the node enters the scene tree for the first time.

#var Ldinohandright = str2var("Transform( -0.667954, 0.204481, 0.715559, -0.111508, 0.923157, -0.367895, -0.735802, -0.325527, -0.593825, -0.681143, 0.784487, 0.170402 )")
#var Ldinohandright = str2var("Transform( -0.667954, 0.204481, 0.715559, -0.111508, 0.923157, -0.367895, -0.735802, -0.325527, -0.593825, 0.262, 0.9, -0.21 )")
var Ldinohandright = str_to_var("Transform3D( 0.942187, 0.0974531, -0.320602, -0.198669, 0.932936, -0.300267, 0.269839, 0.346601, 0.898362, 0.359149, 1.06336, -0.212626 )")
var Lhdino = str_to_var("Transform3D( 0.980819, -0.0376202, -0.191253, -0.00126792, 0.979946, -0.199261, 0.194914, 0.195682, 0.961102, -0.0609239, 1.25416, 0.206489 )")

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_K:
				Ldinohandright.origin.x -= 0.1
			if event.keycode == KEY_L:
				Ldinohandright.origin.x += 0.1


func _physics_process(delta):

	if aplayer.is_playing():
		$FrameStick.transform = $Monster.transform*mskel.get_bone_global_pose(hand_r_control)
		return
	Dt += delta
	if Dt > 1:
		Dt = 0
	if not OpenXRallhandsdata:
		return

	var zheadback = Vector3(OpenXRallhandsdata.headcam_pose.basis.z.x, 0, OpenXRallhandsdata.headcam_pose.basis.z.z).normalized()
	var headcamhorizontalbasis = Basis(Vector3(0,1,0).cross(zheadback), Vector3(0,1,0), zheadback)
	var headcamhorizontaltransform_fromfloor = Transform3D(headcamhorizontalbasis, Vector3(OpenXRallhandsdata.headcam_pose.origin.x, 0, OpenXRallhandsdata.headcam_pose.origin.z))
	
	var humancofgy = 0.8
	var humancofgz = 0.0
	var conjh = Basis().rotated(Vector3(0,1,0), deg_to_rad(180))

	var handcontrollerposeleft = OpenXRallhandsdata.gethandcontrollerpose(false)
	var handcontrollerposeright = OpenXRallhandsdata.gethandcontrollerpose(true)
	if handcontrollerposeright == null:
		handcontrollerposeright = Transform3D(Ldinohandright.basis, Ldinohandright.origin)
	
	# 1. move handrcontrol_bonerestCJ outside, and its inverse, and the handlcontrol
	# 2. get all the code below working as it should
	# 3. find the transforms that match hands to gethandcontrollerpose properly (and less janky)
	# 4. simplify it all down
	# 4.5 could move claws in with grip keys
	# 5. experiment with some verlet integration/IK on the upper arms (recording positions and moving up)
	# 6. experiment with verlet on the spine and neck, and the shoulders
	# 7. everything relative to the central point (with an avatar rotation applied)
	# 8. feet placement follow on to move in a step when the twist force or transmission force too far
	# 9. locomotion done by moving away from the origin position to roll forwards
	# 10. place in as a new avatar, 
	# 11. all of this is a pipe-dream
	# 12. make a phone app version of redovar game.
	
	
	if handcontrollerposeright:
		var handcontrollerpose_relhead = headcamhorizontaltransform_fromfloor.inverse()*handcontrollerposeright
		mskel.set_bone_pose_rotation(hand_r_control, Quaternion(mskel_bonerest_handcontrolR_inverse.basis * handcontrollerpose_relhead.basis * mskel_bonerest_handcontrolR.basis))
		mskel.set_bone_pose_position(hand_r_control, mskel_bonerest_handcontrolR_inverse.basis * (handcontrollerpose_relhead.origin + Vector3(0, -humancofgy, -humancofgz))*dinoscale)

	if handcontrollerposeleft:
		var handcontrollerpose_relhead = headcamhorizontaltransform_fromfloor.inverse()*handcontrollerposeleft
		mskel.set_bone_pose_rotation(hand_l_control, Quaternion(mskel_bonerest_handcontrolL_inverse.basis * handcontrollerpose_relhead.basis * mskel_bonerest_handcontrolL.basis)) 
		mskel.set_bone_pose_position(hand_l_control, mskel_bonerest_handcontrolL_inverse.basis * (handcontrollerpose_relhead.origin + Vector3(0, -humancofgy, -humancofgz))*dinoscale)
	
	var dinohandleft = OpenXRallhandsdata.gethandcontrollerpose(false)
	if dinohandleft != null:
		var dhandleft = Vector3(-dinohandleft.origin.x, dinohandleft.origin.y - humancofgy, -(dinohandleft.origin.z - humancofgz))
		var handlcontrol_bonerest = mskel.get_bone_rest(hand_l_control)
		var sssQ = (dhandleft*dinoscale) * handlcontrol_bonerest
		mskel.set_bone_pose_rotation(hand_l_control, Quaternion(dinohandleft.basis.inverse()))
		#mskel.set_bone_pose_rotation(hand_l_control, Quaternion(dinohandleft.basis.inverse(), sssQ))

	var hhdinobasis = OpenXRallhandsdata.headcam_pose.basis
#	$FrameStick2.transform.basis = hhdinobasis.scaled(Vector3(0.2,0.2,0.2))
#	mskel.set_bone_pose(head, Transform(OpenXRallhandsdata.headcam_pose.basis, Vector3(0,0,0)))
	var conj = Basis().rotated(Vector3(0,1,0), deg_to_rad(180))
	hhdinobasis = conj.inverse()*hhdinobasis*conj
	hhdinobasis = headrestpose.basis.inverse()*hhdinobasis*headrestpose.basis
	mskel.set_bone_pose_rotation(head, Quaternion(hhdinobasis))

	var hhdinohead = headrestpose*Transform3D(hhdinobasis, Vector3(0,0,0))
#	$FrameStick.transform = $Monster.transform*hhdinohead	
