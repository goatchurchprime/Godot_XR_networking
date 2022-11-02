extends Spatial

#var pinrodscene = load("tensegrityexperiments/pinrod.tscn")
#var pinrodscene = load("tensegrityexperiments/pin6dof.tscn")
var pinrodscene
var pickableball = load("tensegrityexperiments/pickableball.tscn")

var verletmotion = true

func addpinjoint(ball1, ball2):
	var pinjoint1 = pinrodscene.instance()
	pinjoint1.ballA = ball1
	pinjoint1.ballB = ball2
	$PinRods.add_child(pinjoint1)
	return pinjoint1

var ball1
var ball2
var pinjoint2

onready var righthandcontroller = get_node("/root/Main/FPController/RightHandController")
onready var lefthandcontroller = get_node("/root/Main/FPController/LeftHandController")

func _ready():
	pinrodscene = load("tensegrityexperiments/pinverlet.tscn") if verletmotion else load("tensegrityexperiments/pinrod.tscn")

	var ball0 = $EndBalls/StaticBall
	ball1 = $EndBalls/GrabBall
	ball1.mode = RigidBody.MODE_KINEMATIC if verletmotion else RigidBody.MODE_RIGID
	pinjoint2 = addpinjoint(ball0, ball1)
	ball2 = pickableball.instance()
	ball2.mode = RigidBody.MODE_KINEMATIC if verletmotion else RigidBody.MODE_RIGID
	ball2.translation = ball1.translation + Vector3(-0.5, 0.1, 0.02)
	$EndBalls.add_child(ball2)
	var pinjoint1 = addpinjoint(ball0, ball2)
	pinjoint2 = addpinjoint(ball1, ball2)

	righthandcontroller.connect("button_pressed", self, "vr_right_button_pressed")
	set_physics_process(verletmotion)
	
func _physics_process(delta):
	if verletmotion:
		for pinrod in $PinRods.get_children():
			var vec = pinrod.ballB.translation - pinrod.ballA.translation
			var d = (vec.length()/pinrod.orgleng - 1.0)
			if abs(d) > 0.051:
				var c = 0.2*delta*d/pinrod.orgleng
				var cvec = c*vec
				if pinrod.ballA.mode == RigidBody.MODE_KINEMATIC and not pinrod.ballA.is_picked_up():
					pinrod.ballA.translation += cvec
				if pinrod.ballB.mode == RigidBody.MODE_KINEMATIC and not pinrod.ballB.is_picked_up():
					pinrod.ballB.translation -= cvec
	
const VR_BUTTON_AX = 7
func vr_right_button_pressed(button: int):
	print("vr right button pressed ", button)
	if button == VR_BUTTON_AX:
		var lefthandobject = lefthandcontroller.get_node("FunctionPickup").picked_up_object
		var righthandobject = righthandcontroller.get_node("FunctionPickup").picked_up_object

		if righthandobject and lefthandobject:
			for pinrod in $PinRods.get_children():
				if (pinrod.ballA == lefthandobject and pinrod.ballB == righthandobject) or \
				   (pinrod.ballB == lefthandobject and pinrod.ballA == righthandobject):
					pinrod.queue_free()
					break
			addpinjoint(lefthandobject, righthandobject)
					
		elif lefthandobject:
			var ball = lefthandobject
			var ballnew = pickableball.instance()
			ballnew.mode = RigidBody.MODE_KINEMATIC if verletmotion else RigidBody.MODE_RIGID
			ballnew.translation = righthandcontroller.global_transform.origin
			$EndBalls.add_child(ballnew)
			addpinjoint(lefthandobject, ballnew)
			#ballnew.pick_up(righthandcontroller.get_node("FunctionPickup"), righthandcontroller)

		elif righthandobject:
			for pinrod in $PinRods.get_children():
				if pinrod.ballA == righthandobject or pinrod.ballB ==righthandobject:
					pinrod.queue_free()
					


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_1:
				$EndBalls/GrabBall.translation += Vector3(0.5,0,0)
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
