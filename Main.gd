extends Spatial

onready var NetworkGateway = $ViewportNetworkGateway/Viewport/NetworkGateway

# BakedLightMap requires the UV2 unwraps on the walls, which can't be 
# done with Boxmeshes it seems.  Then we would hit Bake on the BakeLightMap node

func _ready():
	if OS.has_feature("QUEST"):
		print("kk1 ", $FPController/left_hand_mesh/HandModel/Armature001/Skeleton.hand)
		print("kk2 ", $FPController/right_hand_mesh/HandModel/Armature/Skeleton.hand)
	
	#var brokeraddress = "ws://broker.mqttdashboard.com:8000"
	#var brokeraddress = "broker.mqttdashboard.com"
	#var roomname = "cucumber"
	var roomname = "lettuce"
	var brokeraddress = "mqtt.dynamicdevices.co.uk"
	brokeraddress = NetworkGateway.get_node("MQTTsignalling/brokeraddress").text
	roomname = NetworkGateway.get_node("MQTTsignalling/roomname").text


	#$FPController/LeftHandController/Function_Direct_movement.nonVRkeyboard = true

	# Uncomment if you want the mqtt_webrtc system to begin at startup for the PC
	#NetworkGateway.initialstatemqttwebrtc(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY, roomname, brokeraddress)
	
	# Uncomment if you want the enet-srver system to begin at startup on the PC
#	NetworkGateway.initialstatenormal(NetworkGateway.NETWORK_PROTOCOL.ENET, NetworkGateway.NETWORK_OPTIONS.AS_SERVER)

	get_node("/root").msaa = Viewport.MSAA_4X
	$FPController/RightHandController.connect("button_pressed", self, "vr_right_button_pressed")
	$FPController/RightHandController.connect("button_release", self, "vr_right_button_release")
	$FPController/LeftHandController.connect("button_pressed", self, "vr_left_button_pressed")

	$FPController/PlayerBody.default_physics.move_drag = 45
	$SportBall.connect("body_entered", self, "ball_body_entered")
	$SportBall.connect("body_exited", self, "ball_body_exited")

	NetworkGateway.set_process_input(false)

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

func vr_right_button_pressed(button: int):
	print("vr right button pressed ", button)
	if button == VR_BUTTON_BY:
		if $ViewportNetworkGateway.visible:
			$ViewportNetworkGateway.visible = false
		else:
			var headtrans = $FPController/ARVRCamera.global_transform
			$ViewportNetworkGateway.look_at_from_position(headtrans.origin + headtrans.basis.z*-3, 
														  headtrans.origin + headtrans.basis.z*-3, 
														  Vector3(0, 1, 0))
			$ViewportNetworkGateway.visible = true
			
	if button == VR_GRIP:
		NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(true)

func vr_right_button_release(button: int):
	if button == VR_GRIP:
		NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(false)

func vr_left_button_pressed(button: int):
	print("vr left button pressed ", button)
	if button == VR_BUTTON_BY:
		$SportBall.transform.origin = $FPController/ARVRCamera.global_transform.origin + \
									  Vector3(0, 2, 0) + \
									  $FPController/ARVRCamera.global_transform.basis.z*-0.75
		
			
func _input(event):
	if event is InputEventKey and not event.echo:
		if event.scancode == KEY_M and event.pressed:
			vr_right_button_pressed(VR_BUTTON_BY)
		if event.scancode == KEY_F and event.pressed:
			vr_left_button_pressed(VR_BUTTON_BY)
		if event.scancode == KEY_G and event.pressed:
			NetworkGateway.get_node("PlayerConnections/Doppelganger").pressed = not NetworkGateway.get_node("PlayerConnections/Doppelganger").pressed
		if (event.scancode == KEY_2):
			NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS.LOCAL_NETWORK)
		if event.scancode == KEY_SHIFT:
			vr_right_button_pressed(VR_GRIP) if event.pressed else vr_right_button_release(VR_GRIP)


func _physics_process(delta):
	if $FPController.transform.origin.y < -30:
		$FPController.transform.origin = Vector3(0, 2, 0)
	if has_node("SportBall"):
		if $SportBall.transform.origin.y < -3:
			$SportBall.transform.origin = Vector3(0, 2, -3)

