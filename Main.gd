extends Spatial

onready var NetworkGateway = $ViewportNetworkGateway/Viewport/NetworkGateway

export var webrtcroomname = "lettuce"
export var webrtcbroker = "mqtt.dynamicdevices.co.uk"
# "ws://broker.mqttdashboard.com:8000"
export var PCstartupprotocol = "webrtc"
export var QUESTstartupprotocol = "webrtc"


func _ready():
	if OS.has_feature("QUEST"):
		if has_node("FPController/Right_hand"):
			#$FPController/Left_hand/XRPose.action = "SkeletonBase"
			#$FPController/Left_hand/XRPose.path = "/user/hand/left"
			#$FPController/Right_hand/XRPose.action = "SkeletonBase"
			$FPController/Right_hand/XRPose.path = "/user/hand/right"
			$FPController/Right_hand.hand = 1
			
	else:
		if has_node("FPController/Left_hand"):
			$FPController/Left_hand/Wrist.set_process(false)
			$FPController/Left_hand/Wrist.set_physics_process(false)
		if has_node("FPController/Right_hand"):
			$FPController/Right_hand/Wrist.set_process(false)
			$FPController/Right_hand/Wrist.set_physics_process(false)
	#$FPController/LeftHandController/Function_Direct_movement.nonVRkeyboard = true

	if OS.has_feature("QUEST"):
		if QUESTstartupprotocol == "webrtc":
			NetworkGateway.initialstatemqttwebrtc(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY, webrtcroomname, webrtcbroker)
		elif QUESTstartupprotocol == "enet":
			NetworkGateway.initialstatenormal(NetworkGateway.NETWORK_PROTOCOL.ENET, NetworkGateway.NETWORK_OPTIONS.AS_CLIENT)
	else:
		if PCstartupprotocol == "webrtc":
			NetworkGateway.initialstatemqttwebrtc(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY, webrtcroomname, webrtcbroker)
		elif PCstartupprotocol == "enet":
			NetworkGateway.initialstatenormal(NetworkGateway.NETWORK_PROTOCOL.ENET, NetworkGateway.NETWORK_OPTIONS.AS_SERVER)
			$FPController/PlayerBody

	get_node("/root").msaa = Viewport.MSAA_4X
	$FPController/RightHandController.connect("button_pressed", self, "vr_right_button_pressed")
	$FPController/RightHandController.connect("button_release", self, "vr_right_button_release")
	$FPController/LeftHandController.connect("button_pressed", self, "vr_left_button_pressed")

	$FPController/PlayerBody.default_physics.move_drag = 45
	$SportBall.connect("body_entered", self, "ball_body_entered")
	$SportBall.connect("body_exited", self, "ball_body_exited")

	NetworkGateway.set_process_input(false)
#	$FPController/Left_hand/Wrist.visible = false
#	$FPController/Right_hand/Wrist.visible = false


func ball_body_entered(body):
	#print("ball_body_entered ", body)
	if body.name == "PaddleBody":
		$SportBall/bouncesound.play()
		body.get_node("CollisionShape/MeshInstance").get_surface_material(0).emission_enabled = true
		yield(get_tree().create_timer(0.2), "timeout")
		body.get_node("CollisionShape/MeshInstance").get_surface_material(0).emission_enabled = false
		
func ball_body_exited(body):	
	#if body.name == "PaddleBody":
	#	body.get_node("CollisionShape/MeshInstance").get_surface_material(0).emission_enabled = false
	pass
		

const VR_BUTTON_BY = 1
const VR_BUTTON_AX = 7
const VR_GRIP = 2
const VR_TRIGGER = 15
const VR_BUTTON_4 = 4
const VR_HANDTRACKING_INDEXTHUMB_PINCH = VR_BUTTON_4
	
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
		if NetworkGateway.get_node("PlayerConnections").LocalPlayer.has_method("setpaddlebody"):
			NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(true)

	
func vr_right_button_release(button: int):
	if button == VR_GRIP:
		if NetworkGateway.get_node("PlayerConnections").LocalPlayer.has_method("setpaddlebody"):
			NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(false)

func vr_left_button_pressed(button: int):
	print("vr left button pressd ", button)
	if button == VR_BUTTON_BY:
		$SportBall.transform.origin = $FPController/ARVRCamera.global_transform.origin + \
									  Vector3(0, 2, 0) + \
									  $FPController/ARVRCamera.global_transform.basis.z*-0.75
		
	if button == VR_BUTTON_AX:
		pass
	if button == VR_BUTTON_4:
		$FPController/HandtrackingDevelopment.lefthandfingertap()
		$FPController/Left_hand.visible = not $FPController/Left_hand.visible
		$FPController/Right_hand.visible = not $FPController/Right_hand.visible
			
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
		if event.scancode == KEY_Q and event.pressed:
			var mqtt = get_node("/root/Main/ViewportNetworkGateway/Viewport/NetworkGateway/MQTTsignalling/MQTT")
			mqtt.publish("hand/pos", "hithere")

func _physics_process(delta):
	var lowestfloorheight = -30
	if $FPController.transform.origin.y < lowestfloorheight:
		$FPController.transform.origin = Vector3(0, 2, 0)
	if has_node("SportBall"):
		if $SportBall.transform.origin.y < -3:
			$SportBall.transform.origin = Vector3(0, 2, -3)


func _process(delta):
	if $FPController.interface != null and $FPController/Right_hand.is_active():
		$FPController/RightHandController/Function_pointer.active_button = VR_HANDTRACKING_INDEXTHUMB_PINCH
	else:
		$FPController/RightHandController/Function_pointer.active_button = VR_TRIGGER
	
