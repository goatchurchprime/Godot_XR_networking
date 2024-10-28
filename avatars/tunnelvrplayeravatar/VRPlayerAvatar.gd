extends Node3D

@onready var arvrorigin = XRHelpers.get_xr_origin(get_node("/root/Main/XROrigin3D"))

@onready var LeftHandController = XRHelpers.get_left_controller(arvrorigin)
@onready var RightHandController = XRHelpers.get_right_controller(arvrorigin)

var nextframeisfirst = false

const TRACKING_CONFIDENCE_HIGH = 2
const TRACKING_CONFIDENCE_NOT_APPLICABLE = -1
const TRACKING_CONFIDENCE_NONE = 0

var shrinkavatartransform = Transform3D()

var projectedhands = false
static var selectedtrackslookup = { ^".:position":-1, 
							^".:rotation":-1,
							^"HeadCam:quaternion":-1 }

func _ready():
	var anim : Animation = $PlayerAnimation.get_animation("playeral/trackstemplate")
	for i in anim.get_track_count():
		if selectedtrackslookup.has(anim.track_get_path(i)):
			selectedtrackslookup[anim.track_get_path(i)] = i

var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func PF_initlocalplayer():
	randomize()
	$HeadCam/NameplateLabel3D.text = possibleusernames[randi()%len(possibleusernames)]

func playername():
	return $HeadCam/NameplateLabel3D.text

func PF_spawninfo_fornewplayer():
	var spawnpos = transform.origin + Vector3(1,0,-1.5)
	var spawnrot = transform.basis.get_rotation_quaternion()*Quaternion(Vector3(0,1,0), deg_to_rad(45))
	return { "spawnpointtransform":Transform3D(spawnrot, spawnpos) }

func PF_spawninfo_receivedfromserver(sfd):
	arvrorigin.transform = sfd["spawnpointtransform"]
	
func PF_startupdatafromconnectedplayer(avatardata):
	visible = false

func skelbonescopy(skela, skelb):
	for i in range(skela.get_bone_count()):
		skela.set_bone_pose_rotation(i, skelb.get_bone_pose_rotation(i))

func PF_processlocalavatarposition(delta):
	transform = shrinkavatartransform*arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("XRCamera3D").transform
	$hand_l.transform = arvrorigin.global_transform.inverse()*arvrorigin.get_node("LeftHandController/LeftHand/Hand_Glove_low_L").global_transform
	skelbonescopy($hand_l/Armature/Skeleton3D, arvrorigin.get_node("LeftHandController/LeftHand/Hand_Glove_low_L/Armature/Skeleton3D"))
	$hand_r.transform = arvrorigin.global_transform.inverse()*arvrorigin.get_node("RightHandController/RightHand/Hand_low_R").global_transform
	skelbonescopy($hand_r/Armature/Skeleton3D, arvrorigin.get_node("RightHandController/RightHand/Hand_low_R/Armature/Skeleton3D"))
	if projectedhands:
		var headface = Vector3($HeadCam.transform.basis.z.x, 0, $HeadCam.transform.basis.z.z).normalized()
		var headup = Vector3(headface.x, 0.8, headface.z)*0.25
		$hand_r.transform.origin += Vector3(headface.x*0.2, 0.2, headface.z*0.2)
		$hand_l.transform.origin += Vector3(headface.x*0.2, 0.2, headface.z*0.2)

func PF_setspeakingvolume(v):
	$AudioStreamPlayer/MeshInstance3D.scale.x = v

func setpaddlebody(active):
	$ControllerRight/PaddleBody.visible = active
	$ControllerRight/PaddleBody/CollisionShape3D.disabled = not active

static func PF_changethinnedframedatafordoppelganger(fd, doppelnetoffset):
	fd[NCONSTANTS.CFI_TIMESTAMP] += doppelnetoffset
	fd[NCONSTANTS.CFI_TIMESTAMPPREV] += doppelnetoffset
	var itrackpos = selectedtrackslookup[^".:position"]
	var itrackheadrot = selectedtrackslookup[^"HeadCam:quaternion"]
	if fd.has(NCONSTANTS.CFI_ANIMTRACKS+itrackpos):
		fd[NCONSTANTS.CFI_ANIMTRACKS+itrackpos].z += -2 # should only be set in the spawn point
	if fd.has(NCONSTANTS.CFI_ANIMTRACKS+itrackheadrot):
		print(var_to_str(fd[NCONSTANTS.CFI_ANIMTRACKS+itrackheadrot]))
		fd[NCONSTANTS.CFI_ANIMTRACKS+itrackheadrot] *= Quaternion(Vector3(0, 1, 0), deg_to_rad(180))
