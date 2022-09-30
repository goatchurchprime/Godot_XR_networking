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

var ovrhandrightrestdata = null
var ovrhandleftrestdata = null
func _ready():
	ovrhandrightrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_right_hand_model)
	ovrhandleftrestdata = OpenXRtrackedhand_funcs.getovrhandrestdata($ovr_left_hand_model)
