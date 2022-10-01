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

const avatarbodyrotatedegspersec = 90
const avatarbodyrotatedegseasynecklimit = 8

var rpmavatarskelrestdata = null
func _ready():
	rpmavatarskelrestdata = OpenXRtrackedhand_funcs.getrpmhandrestdata($readyplayerme_avatar)

	var skel = rpmavatarskelrestdata["skel"]
	assert (skel.get_bone_name(4) == "Neck")
	assert (skel.get_bone_name(5) == "Head")
	assert (skel.get_bone_name(7) == "LeftEye")
	assert (skel.get_bone_name(8) == "RightEye")
	assert (skel.get_bone_rest(7).basis.is_equal_approx(skel.get_bone_rest(8).basis))
	rpmavatarskelrestdata["middleeyerestpose"] = Transform(skel.get_bone_rest(7).basis, (skel.get_bone_rest(7).origin + skel.get_bone_rest(8).origin)/2)
	rpmavatarskelrestdata["eyeballdepth"] = skel.get_node("EyeLeft").get_aabb().size.z
	rpmavatarskelrestdata["globalheadrestpose"] = skel.get_bone_global_pose(4)*skel.get_bone_rest(5)

var eyebodyangle = 0.0
func PAV_processlocalavatarposition(delta):
	transform = arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform

	var skel = rpmavatarskelrestdata["skel"] # $readyplayerme_avatar/Armature/Skeleton
	var vrheadcam = $HeadCam.transform
	
	if abs(eyebodyangle) > avatarbodyrotatedegseasynecklimit:
		$readyplayerme_avatar.rotation_degrees.y += avatarbodyrotatedegspersec*delta*sign(eyebodyangle)
	
	var rpmheadcambasis = Basis(-vrheadcam.basis.x, vrheadcam.basis.y, -vrheadcam.basis.z)
	var rpmheadcamposition = vrheadcam.origin - rpmheadcambasis.z*rpmavatarskelrestdata["eyeballdepth"]
	var rpmheadcam = Transform(rpmheadcambasis, rpmheadcamposition)

	var nktrans = rpmheadcam * rpmavatarskelrestdata["middleeyerestpose"].inverse()
	
	# (A.basis, A.origin)*(B.basis, B.origin) = (A.basis*B.basis, A.origin + A.basis*B.origin)
	var skelbasis = $readyplayerme_avatar.transform.basis * $readyplayerme_avatar/Armature.transform.basis * $readyplayerme_avatar/Armature/Skeleton.transform.basis
	var gpos = nktrans.origin - skelbasis.xform(rpmavatarskelrestdata["globalheadrestpose"].origin)
	var bonepose5basis = (skelbasis * rpmavatarskelrestdata["globalheadrestpose"].basis).inverse()*nktrans.basis
	
	$readyplayerme_avatar.transform.origin = gpos
	skel.set_bone_pose(5, Transform(bonepose5basis, Vector3(0,0,0)))
	
	eyebodyangle = rad2deg(atan2(bonepose5basis.z.x, bonepose5basis.z.z)) if abs(bonepose5basis.z.y) < 0.8 else 0.0

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
