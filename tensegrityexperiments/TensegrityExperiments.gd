extends Spatial

var pickableballscene = load("tensegrityexperiments/pickableball.tscn")
var pickablestrutscene = load("tensegrityexperiments/PickableStrut.tscn")
var pickablewirescene = load("tensegrityexperiments/PickableWire.tscn")

onready var righthandcontroller = get_node("/root/Main/FPController/RightHandController")
onready var lefthandcontroller = get_node("/root/Main/FPController/LeftHandController")

func _ready():
	if not visible:
		set_physics_process(false)
		$tensegrityUI.enabled = false
		return
		
	righthandcontroller.connect("button_pressed", self, "vr_right_button_pressed")
	righthandcontroller.connect("button_release", self, "vr_right_button_release")
	righthandcontroller.get_node("FunctionPickup").connect("has_picked_up", self, "vr_right_picked_up")
	righthandcontroller.get_node("FunctionPickup").connect("has_dropped", self, "vr_right_dropped")
	var strut1 = addnewstrut(Transform(Basis(Vector3(1,1,0), deg2rad(45)), Vector3(1,1.15,-0.6)))
	var strut2 = addnewstrut(Transform(Basis(Vector3(1,1,0), deg2rad(45)), Vector3(1.4,1.15,-0.6)))
	addnewwire(strut1.EndBallA, strut2.EndBallB)
	
	var handuihook = lefthandcontroller.get_node("HandUIHook")
	handuihook.remote_path = handuihook.get_path_to($tensegrityUI)

	$tensegrityUI/Viewport/Control/strutplus.connect("pressed", self, "strutplusbutton")
	
	
var ballfromline = null
var pickedwire = null
var pickedwirecontrollerinvbasis = Basis()

func vr_right_picked_up(what):
	if what.get_class() == "XRPickableWire":
		pickedwire = what
		pickedwirecontrollerinvbasis = righthandcontroller.global_transform.basis.inverse()
		$MeshBallLine.transform = pickedwire.transform
		$MeshBallLine.scale.z = pickedwire.min_wirelength
		$MeshBallLine.visible = true
		pickedwire.bpulledsolid = false
		
func vr_right_dropped():
	if pickedwire != null:
		if righthandcontroller.is_button_pressed(VR_BUTTON_AX):
			pickedwire.min_wirelength = $MeshBallLine.scale.z
		$MeshBallLine.visible = false
		pickedwire = null


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
			if righthandclosestobject.get_class() == "XRPickableWire":
				righthandclosestobject.min_wirelength = (righthandclosestobject.EndBallB.translation - righthandclosestobject.EndBallA.translation).length()
				righthandclosestobject.bpulledsolid = true
				
		else:
			addnewstrut(righthandcontroller.global_transform)

func strutplusbutton():
	print("extending all struts by 0.1")
	for wire in $Wires.get_children():
		wire.bpulledsolid = false
	for strut in $Struts.get_children():
		strut.strut_length += 0.1
		strut.get_node("MeshStrut").scale.z = strut.strut_length

var Dwr = 0
func _physics_process(delta):
	if ballfromline:
		var mpt = (ballfromline.translation + righthandcontroller.global_transform.origin)/2
		$MeshBallLine.look_at_from_position(mpt, righthandcontroller.global_transform.origin, Vector3(0,1,0))
		$MeshBallLine.scale.z = (righthandcontroller.global_transform.origin - ballfromline.translation).length()
	if pickedwire:
		if righthandcontroller.is_button_pressed(VR_BUTTON_AX):
			var righthandrot = righthandcontroller.global_transform.basis*pickedwirecontrollerinvbasis
			var wr = rad2deg(Vector2(righthandrot.x.x, righthandrot.x.y).angle())
			if abs(wr - Dwr) > 5:
				print(wr)
				Dwr = wr
			var swr = -wr/180
			if swr > 0.0:
				$MeshBallLine.scale.z = pickedwire.min_wirelength*(1 + swr*3)
			else:
				$MeshBallLine.scale.z = pickedwire.min_wirelength*(1 + swr*0.8)
		else:
			$MeshBallLine.scale.z = pickedwire.min_wirelength
	ballwires(delta)

var ballsumvec = Vector3(0,0,0)
var ballsumN = 0
var ballsumFrame = 0
var pullingspeed = 0.2
var ballFrameN = 0
func ballwires(delta):
	ballFrameN += 1
	var ds = pullingspeed*delta
	for wire in $Wires.get_children():
		if not wire.is_picked_up():
			wire.recpulledwire(ballFrameN, ds)
	for strut in $Struts.get_children():
		strut.setstrutends(ballFrameN)


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
	if visible:
		if event is InputEventKey:
			if event.pressed:
				if event.scancode == KEY_2:
					$Balls/Ball.translation += Vector3(0.5,0,0)
					for wire in $Wires.get_children():
						wire.bpulledsolid = false
