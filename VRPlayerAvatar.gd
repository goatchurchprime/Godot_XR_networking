extends Spatial


onready var arvrorigin = get_node("/root/Main/ARVROrigin")
var labeltext = "unknown"

func processlocalavatarposition(delta):
	transform = arvrorigin.transform
	$HeadCam.transform = arvrorigin.get_node("ARVRCamera").transform
	$HandLeft.transform = arvrorigin.get_node("ARVRController_Left").transform
	$HandRight.transform = arvrorigin.get_node("ARVRController_Right").transform
	$HandLeft/LeftHand/AnimationTree.set("parameters/Grip/blend_amount", arvrorigin.get_node("ARVRController_Left/LeftHand/AnimationTree").get("parameters/Grip/blend_amount"))
	$HandLeft/LeftHand/AnimationTree.set("parameters/Trigger/blend_amount", arvrorigin.get_node("ARVRController_Left/LeftHand/AnimationTree").get("parameters/Trigger/blend_amount"))
	$HandRight/RightHand/AnimationTree.set("parameters/Grip/blend_amount", arvrorigin.get_node("ARVRController_Right/RightHand/AnimationTree").get("parameters/Grip/blend_amount"))
	$HandRight/RightHand/AnimationTree.set("parameters/Trigger/blend_amount", arvrorigin.get_node("ARVRController_Right/RightHand/AnimationTree").get("parameters/Trigger/blend_amount"))

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
														  $HandRight/RightHand/AnimationTree.get("parameters/Trigger/blend_amount"))
			 }
	return fd

func framedatatoavatar(fd):
	transform = Transform(Basis(fd[NCONSTANTS2.CFI_VRORIGIN_ROTATION]), fd[NCONSTANTS2.CFI_VRORIGIN_POSITION])
	$HeadCam.transform = Transform(Basis(fd[NCONSTANTS2.CFI_VRHEAD_ROTATION]), fd[NCONSTANTS2.CFI_VRHEAD_POSITION])
	$HandLeft.transform = Transform(Basis(fd[NCONSTANTS2.CFI_VRHANDLEFT_ROTATION]), fd[NCONSTANTS2.CFI_VRHANDLEFT_POSITION])
	$HandRight.transform = Transform(Basis(fd[NCONSTANTS2.CFI_VRHANDRIGHT_ROTATION]), fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSITION])

	$HandLeft/LeftHand/AnimationTree.set("parameters/Grip/blend_amount", fd[NCONSTANTS2.CFI_VRHANDLEFT_POSE].x) 
	$HandLeft/LeftHand/AnimationTree.set("parameters/Trigger/blend_amount", fd[NCONSTANTS2.CFI_VRHANDLEFT_POSE].y) 
	$HandRight/RightHand/AnimationTree.set("parameters/Grip/blend_amount", fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSE].x) 
	$HandRight/RightHand/AnimationTree.set("parameters/Trigger/blend_amount", fd[NCONSTANTS2.CFI_VRHANDRIGHT_POSE].y) 


var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func initavatarlocal():
	randomize()
	labeltext = possibleusernames[randi()%len(possibleusernames)]

func initavatarremote(avatardata):
	labeltext = avatardata["labeltext"]

func avatarinitdata():
	var avatardata = { "avatarsceneresource":filename, 
					   "labeltext":labeltext
					 }
	return avatardata
	
static func changethinnedframedatafordoppelganger(fd, doppelnetoffset):
	fd[NCONSTANTS.CFI_TIMESTAMP] += doppelnetoffset
	fd[NCONSTANTS.CFI_TIMESTAMPPREV] += doppelnetoffset
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_POSITION):
		fd[NCONSTANTS2.CFI_VRORIGIN_POSITION].z += -2
	if fd.has(NCONSTANTS2.CFI_VRORIGIN_ROTATION):
		fd[NCONSTANTS2.CFI_VRORIGIN_ROTATION] *= Quat(Vector3(0, 1, 0), deg2rad(180))
