extends Spatial

onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"
onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var Left_hand = arvrorigin.get_node_or_null("Left_hand")
onready var Right_hand = arvrorigin.get_node_or_null("Right_hand")
onready var Configuration = arvrorigin.get_node_or_null("Configuration")
onready var XRPoseLeftHand = arvrorigin.get_node_or_null("Left_hand/XRPose")
onready var XRPoseRightHand = arvrorigin.get_node_or_null("Right_hand/XRPose")

const TRACKING_CONFIDENCE_HIGH = 2

func _ready():
	pass

func PAV_processlocalavatarposition(delta):
	transform = arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform

	var skel = $readyplayerme_avatar/Armature/Skeleton
	#skel.get_node("Wolf3D_Hair").visible = false
	#skel.get_node("Wolf3D_Head").visible = false
	assert (skel.get_bone_name(4) == "Neck")
	assert (skel.get_bone_name(5) == "Head")
	assert (skel.get_bone_name(7) == "LeftEye")
	assert (skel.get_bone_name(8) == "RightEye")
	
	var headpose = skel.global_transform*skel.get_bone_global_pose(5)
	assert (skel.get_bone_rest(7).basis.is_equal_approx(skel.get_bone_rest(8).basis))
	var middleeyerestpose = Transform(skel.get_bone_rest(7).basis, (skel.get_bone_rest(7).origin + skel.get_bone_rest(8).origin)/2)
	
	var RPMeyeballdepth = skel.get_node("EyeLeft").get_aabb().size.z
	#$MeshInstance_marker.transform.origin = headpose.origin
	#var middleeyerestG = headpose*middleeyerestpose
	
	var vrheadcam = $HeadCam.global_transform
	var rpmheadcambasis = Basis(-vrheadcam.basis.x, vrheadcam.basis.y, -vrheadcam.basis.z)
	var rpmheadcamposition = vrheadcam.origin - rpmheadcambasis.z*RPMeyeballdepth
	var rpmheadcam = Transform(rpmheadcambasis, rpmheadcamposition)
	var bp45 = skel.get_bone_global_pose(4)*skel.get_bone_rest(5)
	# skel.global_transform*skel.get_bone_global_pose(4)*skel.get_bone_rest(5)*bonepose5*middleeyerestpose == rpmheadcam
	var nktrans = rpmheadcam*middleeyerestpose.inverse()
	# skel.global_transform*bp45*bonepose5 == rpmheadcam*middleeyerestpose.inverse()
	
	# (A.basis, A.origin)*(B.basis, B.origin) = (A.basis*B.basis, A.origin + A.basis*B.origin)
	var gbasis = skel.global_transform.basis
	# (gbasis, gpos)*(bp45.basis, bp45.pos)*(bonepose5basis, 0) = nktrans
	# (gbasis, gpos)*(bp45.basis*bonepose5basis, bp45.pos) = (nktrans.basis, nktrans.pos)
	# (gbasis*bp45.basis*bonepose5basis, gpos + gbasis*bp45.pos) = (nktrans.basis, nktrans.pos)
	var gpos = nktrans.origin - gbasis.xform(bp45.origin)
	var bonepose5basis = (gbasis*bp45.basis).inverse()*nktrans.basis
	
	#$MeshInstance_marker2.transform.origin = middleeyerestG.origin + middleeyerestG.basis.z*RPMeyeballdepth
	#$MeshInstance_marker.transform.origin = middleeyerestG.origin + Vector3(0,0.02,0)
	$readyplayerme_avatar.transform.origin = gpos
	skel.set_bone_pose(5, Transform(bonepose5basis, Vector3(0,0,0)))

	transform.origin += Vector3(0,0,-2)

func PAV_avatartoframedata():
	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
			 }
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

func PAV_initavatarlocal():
	labeltext = "ding"

func PAV_initavatarremote(avatardata):
	labeltext = avatardata["labeltext"]

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
