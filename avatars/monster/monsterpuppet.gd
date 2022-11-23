extends Spatial

onready var mskel = $Monster/Origin/MonsterArmature/Skeleton
onready var aplayer = $Monster/Origin/AnimationPlayer
onready var OpenXRallhandsdata = get_node("../FPController/OpenXRallhandsdata")

onready var forearm_r = mskel.find_bone("forearm_r")         # 7
onready var hand_r = mskel.find_bone("hand_r")               # 28
onready var hand_r_control = mskel.get_bone_parent(hand_r)   # 27 arm_control_r

onready var forearm_l = mskel.find_bone("forearm_l")         # 6
onready var hand_l = mskel.find_bone("hand_l")               # 21
onready var hand_l_control = mskel.get_bone_parent(hand_l)   # 20 arm_control_l
onready var pelvis = mskel.find_bone("pelvis")               # 0
onready var chest = mskel.find_bone("chest")                 # 1
onready var neck = mskel.find_bone("neck")                   # 2
onready var head = mskel.find_bone("head")                   # 3
onready var headrestpose = mskel.get_bone_global_pose(head)

func _ready():
	aplayer.play("throw")

var Dt = 0
onready var dinoscale = 1.0/$Monster.scale.x

# Called when the node enters the scene tree for the first time.

#var Ldinohandright = str2var("Transform( -0.667954, 0.204481, 0.715559, -0.111508, 0.923157, -0.367895, -0.735802, -0.325527, -0.593825, -0.681143, 0.784487, 0.170402 )")
#var Ldinohandright = str2var("Transform( -0.667954, 0.204481, 0.715559, -0.111508, 0.923157, -0.367895, -0.735802, -0.325527, -0.593825, 0.262, 0.9, -0.21 )")
var Ldinohandright = str2var("Transform( 0.942187, 0.0974531, -0.320602, -0.198669, 0.932936, -0.300267, 0.269839, 0.346601, 0.898362, 0.359149, 1.06336, -0.212626 )")
var Lhdino = str2var("Transform( 0.980819, -0.0376202, -0.191253, -0.00126792, 0.979946, -0.199261, 0.194914, 0.195682, 0.961102, -0.0609239, 1.25416, 0.206489 )")

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_K:
				Ldinohandright.origin.x -= 0.1
			if event.scancode == KEY_L:
				Ldinohandright.origin.x += 0.1


func _physics_process(delta):

	if aplayer.is_playing():
		$FrameStick.transform = $Monster.transform*mskel.get_bone_global_pose(hand_r_control)
		return

	var zheadback = Vector3(OpenXRallhandsdata.headcam_pose.basis.z.x, 0, OpenXRallhandsdata.headcam_pose.basis.z.z).normalized()
	var headcamhorizontalbasis = Basis(Vector3(0,1,0).cross(zheadback), Vector3(0,1,0), zheadback)
	var headcamhorizontaltransform = Transform(headcamhorizontalbasis, Vector3(OpenXRallhandsdata.headcam_pose.origin.x, 0, OpenXRallhandsdata.headcam_pose.origin.z))
	
	var dinohandright = null
	if OpenXRallhandsdata.pointer_pose_confidence_R != OpenXRallhandsdata.TRACKING_CONFIDENCE_NOT_APPLICABLE:
		dinohandright = OpenXRallhandsdata.pointer_pose_transform_R
	if OpenXRallhandsdata.palm_joint_confidence_R == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH:
		dinohandright = OpenXRallhandsdata.joint_transforms_R[OpenXRallhandsdata.XR_HAND_JOINT_WRIST_EXT]
	if dinohandright == null:
		dinohandright = Ldinohandright
		#return
	else:
		dinohandright = headcamhorizontaltransform.inverse()*dinohandright
		Dt += delta
		if Dt > 1:
			Dt = 0
			#print("dino ", var2str(dinohandright))
			print("hdino ", var2str(OpenXRallhandsdata.headcam_pose))
	var dinohandleft = null
	if OpenXRallhandsdata.pointer_pose_confidence_L != OpenXRallhandsdata.TRACKING_CONFIDENCE_NOT_APPLICABLE:
		dinohandleft = OpenXRallhandsdata.pointer_pose_transform_L
	if OpenXRallhandsdata.palm_joint_confidence_L == OpenXRallhandsdata.TRACKING_CONFIDENCE_HIGH:
		dinohandleft = OpenXRallhandsdata.joint_transforms_L[OpenXRallhandsdata.XR_HAND_JOINT_WRIST_EXT]

	var humancofgy = 0.8
	var humancofgz = 0.6
	if dinohandright != null:
		var dhandright = Vector3(-dinohandright.origin.x, dinohandright.origin.y - humancofgy, -(dinohandright.origin.z - humancofgz))
		$FrameStick2.transform = Transform(dinohandright.basis.scaled(Vector3(0.2,0.2,0.2)), Ldinohandright.origin)
		var handrcontrol_bonerest = mskel.get_bone_rest(hand_r_control)
		var sssP = handrcontrol_bonerest.xform_inv(dhandright*dinoscale)
		mskel.set_bone_pose(hand_r_control, Transform(dinohandright.basis.inverse(), sssP))
		$FrameStick.transform = $Monster.transform*mskel.get_bone_global_pose(hand_r_control)
	
	if dinohandleft != null:
		var dhandleft = Vector3(-dinohandleft.origin.x, dinohandleft.origin.y - humancofgy, -(dinohandright.origin.z - humancofgz))
		var handlcontrol_bonerest = mskel.get_bone_rest(hand_l_control)
		var sssQ = handlcontrol_bonerest.xform_inv(dhandleft*dinoscale)
		mskel.set_bone_pose(hand_l_control, Transform(dinohandleft.basis.inverse(), sssQ))

	var hhdinobasis = Lhdino.basis.rotated(Vector3(0,0,1), deg2rad(20))
	hhdinobasis = OpenXRallhandsdata.headcam_pose.basis
	$FrameStick2.transform.basis = hhdinobasis.scaled(Vector3(0.2,0.2,0.2))
#	mskel.set_bone_pose(head, Transform(OpenXRallhandsdata.headcam_pose.basis, Vector3(0,0,0)))
	var conj = Basis.rotated(Vector3(0,1,0), deg2rad(180))
	hhdinobasis = conj.inverse()*hhdinobasis*conj
	hhdinobasis = headrestpose.basis.inverse()*hhdinobasis*headrestpose.basis
	mskel.set_bone_pose(head, Transform(hhdinobasis, Vector3(0,0,0)))

	var hhdinohead = headrestpose*Transform(hhdinobasis, Vector3(0,0,0))
	$FrameStick.transform = $Monster.transform*hhdinohead	
