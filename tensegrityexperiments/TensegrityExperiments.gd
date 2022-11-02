extends Spatial

var pickableballscene = load("tensegrityexperiments/pickableball.tscn")
var pickablestrutscene = load("tensegrityexperiments/PickableStrut.tscn")
var pickablewirescene = load("tensegrityexperiments/PickableWire.tscn")

onready var righthandcontroller = get_node("/root/Main/FPController/RightHandController")
onready var lefthandcontroller = get_node("/root/Main/FPController/LeftHandController")

func _ready():
	righthandcontroller.connect("button_pressed", self, "vr_right_button_pressed")
	righthandcontroller.connect("button_release", self, "vr_right_button_release")
	var strut1 = addnewstrut(Transform(Basis(Vector3(0,1,0), deg2rad(45)), Vector3(0,1.15,-0.6)))
	var strut2 = addnewstrut(Transform(Basis(Vector3(0,1,0), deg2rad(45)), Vector3(0.4,1.15,-0.6)))
	addnewwire(strut1.EndBallA, strut2.EndBallB)
	
var ballfromline = null

const VR_BUTTON_AX = 7
func vr_right_button_pressed(button: int):
	print("--vr right button pressed ", button)
	if button == VR_BUTTON_AX:
		var lefthandobject = lefthandcontroller.get_node("FunctionPickup").picked_up_object
		var righthandobject = righthandcontroller.get_node("FunctionPickup").picked_up_object
		var righthandclosestobject = righthandcontroller.get_node("FunctionPickup").closest_object

		if righthandobject and lefthandobject:
			print("** ", righthandobject.get_class())
					
		elif lefthandobject:
			print("** ", lefthandobject.get_class())
			
		elif righthandobject:
			print("** ", righthandobject.get_class())

		elif righthandclosestobject:
			if righthandclosestobject.get_class() == "XRPickableBall":
				ballfromline = righthandclosestobject
				print("ballfromline ", ballfromline)
				$MeshBallLine.visible = true
				
		else:
			addnewstrut(righthandcontroller.global_transform)

func _physics_process(delta):
	if ballfromline:
		var mpt = (ballfromline.translation + righthandcontroller.global_transform.origin)/2
		$MeshBallLine.look_at_from_position(mpt, righthandcontroller.global_transform.origin, Vector3(0,1,0))
		$MeshBallLine.scale.z = (righthandcontroller.global_transform.origin - ballfromline.translation).length()

func vr_right_button_release(button: int):
	print("--vr right button release ", button)
	if button == VR_BUTTON_AX:
		if ballfromline:
			var righthandclosestobject = righthandcontroller.get_node("FunctionPickup").closest_object
			if righthandclosestobject and righthandclosestobject.get_class() == "XRPickableBall":
				if ballfromline != righthandclosestobject:
					addnewwire(ballfromline, righthandclosestobject)
			$MeshBallLine.visible = false
			ballfromline = null
			
func addnewstrut(stransform):
	var pickablestrut = pickablestrutscene.instance()
	pickablestrut.transform = stransform
	pickablestrut.EndBallA = pickableballscene.instance()
	pickablestrut.EndBallB = pickableballscene.instance()
	pickablestrut.EndBallA.translation = pickablestrut.transform.xform(Vector3(0, 0, pickablestrut.strut_length/2))
	pickablestrut.EndBallB.translation = pickablestrut.transform.xform(Vector3(0, 0, -pickablestrut.strut_length/2))
	$Balls.add_child(pickablestrut.EndBallA)
	$Balls.add_child(pickablestrut.EndBallB)
	$Struts.add_child(pickablestrut)
	return pickablestrut

func addnewwire(ballA, ballB):
	for wire in $Wires.get_children():
		if (wire.EndBallA == ballA and wire.EndBallB == ballB) or (wire.EndBallA == ballB and wire.EndBallB == ballA):
			wire.queue_free()
			return
	var pickablewire = pickablewirescene.instance()
	pickablewire.EndBallA = ballA
	pickablewire.EndBallB = ballB
	pickablewire.min_wirelength = (ballB.translation - ballA.translation).length()
	$Wires.add_child(pickablewire)

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_2:
				$Balls/Ball.translation += Vector3(0.5,0,0)
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
