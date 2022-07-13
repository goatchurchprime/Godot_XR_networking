extends Spatial


onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"

onready var arvrcamera = arvrorigin.get_node("ARVRCamera")
onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var Left_hand = arvrorigin.get_node_or_null("TLeft_hand/Left_hand")
onready var Right_hand = arvrorigin.get_node_or_null("TRight_hand/Right_hand")
onready var Configuration = arvrorigin.get_node_or_null("Configuration")
onready var XRPoseLeftHand = arvrorigin.get_node_or_null("TLeft_hand/XRPose")
onready var XRPoseRightHand = arvrorigin.get_node_or_null("TRight_hand/XRPose")

const TRACKING_CONFIDENCE_HIGH = 2


var ovrbonemapping = { 2:"Wrist/ThumbMetacarpal", 3:"Wrist/ThumbMetacarpal/ThumbProximal", 4:"Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal", 
					   6:"Wrist/IndexMetacarpal/IndexProximal", 7:"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate", 8:"Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal", 
					   10:"Wrist/MiddleMetacarpal/MiddleProximal", 11:"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate", 12:"Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal", 
					   14:"Wrist/RingMetacarpal/RingProximal", 15:"Wrist/RingMetacarpal/RingProximal/RingIntermediate", 16:"Wrist/RingMetacarpal/RingProximal/RingIntermediate/RingDistal", 
					   19:"Wrist/LittleMetacarpal/LittleProximal", 20:"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate", 21:"Wrist/LittleMetacarpal/LittleProximal/LittleIntermediate/LittleDistal" 
					 }
					
var qconj = Quat(0,sqrt(0.5),0,sqrt(0.5))
var qconjI = Quat(qconj.x, qconj.y, qconj.z, -qconj.w)
var qconjT = Quat(sqrt(0.5),0,0,-sqrt(0.5))
var qconjTI = Quat(qconjT.x, qconjT.y, qconjT.z, -qconjT.w)
func processtoovrhand(xrhand, ovrskel, refl):
	for boneid in ovrbonemapping:
		var xrbonepath = ovrbonemapping[boneid]
		var xrbonetransT = xrhand.get_node(xrbonepath).transform
		var xrbonetrans = xrbonetransT.basis
		var qxrbonetrans = xrbonetrans.get_rotation_quat()
		if refl:
			qxrbonetrans = Quat(qxrbonetrans.x, -qxrbonetrans.y, -qxrbonetrans.z, qxrbonetrans.w)  # Conjugating with R=Basis(-i,j,k)
		var qxrbonetransR
		if boneid <= 4:
			qxrbonetransR = qconjT*qxrbonetrans*qconjTI
			if boneid == 2:
				qxrbonetransR = Quat(-0.651024, -0.147317, -0.376364, -0.642507)*qxrbonetransR
		else:
			qxrbonetransR = qconj*qxrbonetrans*qconjI
		var bonerest = ovrskel.get_bone_rest(boneid)
		var qbonepose = bonerest.basis.get_rotation_quat().inverse()*qxrbonetransR
		ovrskel.set_bone_pose(boneid, Transform(qbonepose))

#var leftthumbindextouched = false
		#var grip = controller.get_joystick_axis(JOY_VR_ANALOG_GRIP)
		#var trigger = controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)
		#var thumbtippos = Left_hand.get_node("Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip").global_transform.origin
		#var indextippos = Left_hand.get_node("Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip").global_transform.origin
		#if not leftthumbindextouched:
		#	leftthumbindextouched = (thumbtippos.distance_to(indextippos) < 0.01)
		#	leftthumbindexjusttouched = leftthumbindextouched
		#else:
		#	leftthumbindextouched = (thumbtippos.distance_to(indextippos) < 0.02)

func processlocalavatarposition(delta):
	transform = arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	var handtrackingavailable = (arvrorigin.interface != null)
	if LeftHandController.get_is_active():
		$HandLeft.visible = false
		$ControllerLeft.transform = LeftHandController.transform
		$ControllerLeft.visible = true
		print(Configuration.get_tracking_confidence(1), Configuration.get_tracking_confidence(2), XRPoseLeftHand.get_tracking_confidence(), XRPoseRightHand.get_tracking_confidence())

	elif is_instance_valid(Left_hand) and handtrackingavailable and Left_hand.is_active() and XRPoseLeftHand.get_tracking_confidence() == TRACKING_CONFIDENCE_HIGH:
		$ControllerLeft.visible = false
		$HandLeft.transform = Left_hand.transform
		processtoovrhand(Left_hand, $HandLeft/ovr_left_hand_model/ArmatureLeft/Skeleton, true)
		$HandLeft.visible = true
		print(Configuration.get_tracking_confidence(1), Configuration.get_tracking_confidence(2), XRPoseLeftHand.get_tracking_confidence(), XRPoseRightHand.get_tracking_confidence())

	else:
		$HandLeft.visible = false
		$ControllerLeft.visible = false
			
	if RightHandController.get_is_active():
		$HandRight.visible = false
		$ControllerRight.transform = RightHandController.transform
		$ControllerRight.visible = true
	elif is_instance_valid(Right_hand) and handtrackingavailable and Right_hand.is_active(): # and XRPoseRightHand.get_tracking_confidence() == TRACKING_CONFIDENCE_HIGH:
		$ControllerRight.visible = false
		$HandRight.transform = Right_hand.transform  
		processtoovrhand(Right_hand, $HandRight/ovr_right_hand_model/ArmatureRight/Skeleton, false)
		$HandRight.visible = true
	else:
		$HandRight.visible = false
		$ControllerRight.visible = false

func setpaddlebody(active):
	$ControllerRight/PaddleBody.visible = active
	$ControllerRight/PaddleBody/CollisionShape.disabled = not active

func avatartoframedata():
	var chleft = $HandLeft if $HandLeft.visible else $ControllerLeft
	var chright = $HandRight if $HandRight.visible else $ControllerRight

	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quat(), 
				
				NCONSTANTS2.CFI_VRHANDLEFT_POSITION: chleft.transform.origin, 
				NCONSTANTS2.CFI_VRHANDLEFT_ROTATION: chleft.transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHANDRIGHT_POSITION: chright.transform.origin, 
				NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION: chright.transform.basis.get_rotation_quat(),

				NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY: $ControllerRight/PaddleBody.visible
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

func framedatatoavatar(fd):
	transform = overwritetranform(transform, fd.get(NCONSTANTS2.CFI_VRORIGIN_ROTATION), fd.get(NCONSTANTS2.CFI_VRORIGIN_POSITION))
	$HeadCam.transform = overwritetranform($HeadCam.transform, fd.get(NCONSTANTS2.CFI_VRHEAD_ROTATION), fd.get(NCONSTANTS2.CFI_VRHEAD_POSITION))
	$ControllerLeft.transform = overwritetranform($ControllerLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
	$ControllerRight.transform = overwritetranform($ControllerRight.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))
	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("remote setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
		setpaddlebody(fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
		
var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func initavatarlocal():
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]
	$HandLeft/ovr_left_hand_model/ArmatureLeft/Skeleton/l_handMeshNode.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))
	$HandRight/ovr_right_hand_model/ArmatureRight/Skeleton/r_handMeshNode.set_surface_material(0, load("res://xrassets/vrhandmaterial.tres"))

func initavatarremote(avatardata):
	labeltext = avatardata["labeltext"]

func avatarinitdata():
	var avatardata = { "avatarsceneresource":filename, 
					   "labeltext":labeltext
					 }
	return avatardata
	


static func changethinnedframedatafordoppelganger(fd, doppelnetoffset, isframe0):
	fd[NCONSTANTS.CFI_TIMESTAMP] += doppelnetoffset
	fd[NCONSTANTS.CFI_TIMESTAMPPREV] += doppelnetoffset
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_POSITION):
		if isframe0:
			fd[NCONSTANTS2.CFI_VRORIGIN_POSITION].z += -2
		else:
			fd.erase(NCONSTANTS2.CFI_VRORIGIN_POSITION)
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_ROTATION):
		fd[NCONSTANTS2.CFI_VRORIGIN_ROTATION] *= Quat(Vector3(0, 1, 0), deg2rad(180))

	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("OPP setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
