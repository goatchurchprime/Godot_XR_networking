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
	#$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform

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
