extends Spatial


func _ready():
	
	get_node("/root").msaa = Viewport.MSAA_4X
	$FPController/PlayerBody.default_physics.move_drag = 45
	$SportBall.connect("body_entered", self, "ball_body_entered")
	$SportBall.connect("body_exited", self, "ball_body_exited")

func ball_body_entered(body):
	#print("ball_body_entered ", body)
	if body.name == "PaddleBody":
		$SportBall/bouncesound.play()
		body.get_node("CollisionShape/MeshInstance").get_surface_material(0).emission_enabled = true
		yield(get_tree().create_timer(0.2), "timeout")
		body.get_node("CollisionShape/MeshInstance").get_surface_material(0).emission_enabled = false
		
func ball_body_exited(body):	pass
	#if body.name == "PaddleBody":
	#	body.get_node("CollisionShape/MeshInstance").get_surface_material(0).emission_enabled = false
		

const VR_BUTTON_BY = 1
const VR_BUTTON_AX = 7
const VR_GRIP = 2
const VR_TRIGGER = 15

func vr_left_button_pressed(button: int):
	print("vr left button pressed ", button)
	if button == VR_BUTTON_BY:
		$SportBall.transform.origin = $FPController/ARVRCamera.global_transform.origin + \
									  Vector3(0, 2, 0) + \
									  $FPController/ARVRCamera.global_transform.basis.z*-0.75
		
func _input(event):
	if event is InputEventKey and not event.echo:
		if event.scancode == KEY_F and event.pressed:
			vr_left_button_pressed(VR_BUTTON_BY)
	
			
func _physics_process(delta):
	var lowestfloorheight = -30
	if $FPController.transform.origin.y < lowestfloorheight:
		$FPController.transform.origin = Vector3(0, 2, 0)
	if has_node("SportBall"):
		if $SportBall.transform.origin.y < -3:
			$SportBall.transform.origin = Vector3(0, 2, -3)

##mqtt.dynamicdevices.co.uk
