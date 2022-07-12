extends Spatial


onready var arvrorigin = get_node("/root/Main/FPController")
var labeltext = "unknown"

onready var arvrcamera = arvrorigin.get_node("ARVRCamera")
onready var LeftHandController = arvrorigin.get_node("LeftHandController")
onready var RightHandController = arvrorigin.get_node("RightHandController")
onready var Left_hand = arvrorigin.get_node_or_null("Left_hand")
onready var Right_hand = arvrorigin.get_node_or_null("Right_hand")


	

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

var leftthumbindextouched = false
var rightthumbindextouched = false
func processlocalavatarposition(delta):
	transform = arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	var handtrackingavailable = (arvrorigin.interface != null)
	var leftthumbindexjusttouched = false
	var rightthumbindexjusttouched = false
	
	if LeftHandController.get_is_active():
		$HandLeft.transform = LeftHandController.transform
		$HandLeft/LeftHand/AnimationTree.set("parameters/Trigger/blend_amount", arvrorigin.get_node("LeftHandController/LeftHand/AnimationTree").get("parameters/Trigger/blend_amount"))
		$HandLeft/LeftHand/AnimationTree.set("parameters/Grip/blend_amount", arvrorigin.get_node("LeftHandController/LeftHand/AnimationTree").get("parameters/Grip/blend_amount"))
	elif is_instance_valid(Left_hand) and handtrackingavailable and Left_hand.is_active():
		$HandLeft.transform = Transform(Left_hand.transform.basis.rotated(Left_hand.transform.basis.z, deg2rad(-90)), Left_hand.transform.origin)
		var thumbtippos = Left_hand.get_node("Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip").global_transform.origin
		var indextippos = Left_hand.get_node("Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip").global_transform.origin
		var middletippos = Left_hand.get_node("Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal/MiddleTip").global_transform.origin
		$HandLeft/LeftHand/AnimationTree.set("parameters/Trigger/blend_amount", max(0.0, 1.0 - thumbtippos.distance_to(indextippos)/0.04))
		$HandLeft/LeftHand/AnimationTree.set("parameters/Grip/blend_amount", max(0.0, 1.0 - thumbtippos.distance_to(middletippos)/0.04))

		$HandLeftOVR.transform = Left_hand.transform  # $HandRight.transform
		processtoovrhand(Left_hand, $HandLeftOVR/ovr_left_hand_model/ArmatureLeft/Skeleton, true)

		if not leftthumbindextouched:
			leftthumbindextouched = (thumbtippos.distance_to(indextippos) < 0.01)
			leftthumbindexjusttouched = leftthumbindextouched
		else:
			leftthumbindextouched = (thumbtippos.distance_to(indextippos) < 0.02)

		
	if RightHandController.get_is_active():
		$HandRight.transform = RightHandController.transform
		$HandRight/RightHand/AnimationTree.set("parameters/Trigger/blend_amount", arvrorigin.get_node("RightHandController/RightHand/AnimationTree").get("parameters/Trigger/blend_amount"))
		$HandRight/RightHand/AnimationTree.set("parameters/Grip/blend_amount", arvrorigin.get_node("RightHandController/RightHand/AnimationTree").get("parameters/Grip/blend_amount"))
	elif is_instance_valid(Right_hand) and handtrackingavailable and Right_hand.is_active():
		$HandRight.transform = Transform(Right_hand.transform.basis.rotated(Right_hand.transform.basis.z, deg2rad(90)), Right_hand.transform.origin)
		var thumbtippos = Right_hand.get_node("Wrist/ThumbMetacarpal/ThumbProximal/ThumbDistal/ThumbTip").global_transform.origin
		var indextippos = Right_hand.get_node("Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip").global_transform.origin
		var middletippos = Right_hand.get_node("Wrist/MiddleMetacarpal/MiddleProximal/MiddleIntermediate/MiddleDistal/MiddleTip").global_transform.origin
		$HandRight/RightHand/AnimationTree.set("parameters/Trigger/blend_amount", max(0.0, 1.0 - thumbtippos.distance_to(indextippos)/0.04))
		$HandRight/RightHand/AnimationTree.set("parameters/Grip/blend_amount", max(0.0, 1.0 - thumbtippos.distance_to(middletippos)/0.04))

		$HandRightOVR.transform = Right_hand.transform  
		processtoovrhand(Right_hand, $HandRightOVR/ovr_right_hand_model/ArmatureRight/Skeleton, false)

		if not rightthumbindextouched:
			rightthumbindextouched = (thumbtippos.distance_to(indextippos) < 0.01)
			rightthumbindexjusttouched = rightthumbindextouched
		else:
			rightthumbindextouched = (thumbtippos.distance_to(indextippos) < 0.02)


func setpaddlebody(active):
	$HandRight/PaddleBody.visible = active
	$HandRight/PaddleBody/CollisionShape.disabled = not active

func avatartoframedata():

	var fd = {  NCONSTANTS2.CFI_VRORIGIN_POSITION: transform.origin, 
				NCONSTANTS2.CFI_VRORIGIN_ROTATION: transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHEAD_POSITION: $HeadCam.transform.origin, 
				NCONSTANTS2.CFI_VRHEAD_ROTATION: $HeadCam.transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHANDLEFT_POSITION: $HandLeft.transform.origin, 
				NCONSTANTS2.CFI_VRHANDLEFT_ROTATION: $HandLeft.transform.basis.get_rotation_quat(), 
				NCONSTANTS2.CFI_VRHANDRIGHT_POSITION: $HandRight.transform.origin, 
				NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION: $HandRight.transform.basis.get_rotation_quat(),
				NCONSTANTS2.CFI_VRHANDLEFT_POSE: Vector2($HandLeft/LeftHand/AnimationTree.get("parameters/Grip/blend_amount"), 
														 $HandLeft/LeftHand/AnimationTree.get("parameters/Trigger/blend_amount")),
				NCONSTANTS2.CFI_VRHANDRIGHT_POSE: Vector2($HandRight/RightHand/AnimationTree.get("parameters/Grip/blend_amount"), 
														  $HandRight/RightHand/AnimationTree.get("parameters/Trigger/blend_amount")),

				NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY: $HandRight/PaddleBody.visible
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
	$HandLeft.transform = overwritetranform($HandLeft.transform, fd.get(NCONSTANTS2.CFI_VRHANDLEFT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDLEFT_POSITION))
	$HandRight.transform = overwritetranform($HandRight.transform, fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION), fd.get(NCONSTANTS2.CFI_VRHANDRIGHT_POSITION))
	if fd.has(NCONSTANTS2.CFI_VRHANDLEFT_POSE):
		$HandLeft/LeftHand/AnimationTree.set("parameters/Grip/blend_amount", fd[NCONSTANTS2.CFI_VRHANDLEFT_POSE].x) 
		$HandLeft/LeftHand/AnimationTree.set("parameters/Trigger/blend_amount", fd[NCONSTANTS2.CFI_VRHANDLEFT_POSE].y) 
	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_POSE):
		$HandRight/RightHand/AnimationTree.set("parameters/Grip/blend_amount", fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSE].x) 
		$HandRight/RightHand/AnimationTree.set("parameters/Trigger/blend_amount", fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSE].y) 
	if fd.has(NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY):
		print("remote setpaddlebody ", fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
		setpaddlebody(fd[NCONSTANTS2.CFI_VRHANDRIGHT_PADDLEBODY])
		
var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func initavatarlocal():
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]
	$HandLeft/LeftHand/LeftHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("vrhandmaterial.tres"))
	$HandRight/RightHand/RightHand/Armature_Left/Skeleton/Hand_Left.set_surface_material(0, load("vrhandmaterial.tres"))

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
