extends Node3D

@onready var NetworkGateway = $ViewportNetworkGateway/Viewport/NetworkGateway

@export var webrtcroomname = "grapefruit"

#export var webrtcbroker = "mosquitto.doesliverpool.xyz"

# use this one for WebXR because it can only come from HTML5 served from an https:// link
@export var webrtcbroker = "wss://mosquitto.doesliverpool.xyz:8081"  
#export var webrtcbroker = "ws://mosquitto.doesliverpool.xyz:8080"
#export var webrtcbroker = "ssl://mosquitto.doesliverpool.xyz:8884"
#export var webrtcbroker = "mosquitto.doesliverpool.xyz:1883"


# "ws://broker.mqttdashboard.com:8000"
@export var PCstartupprotocol = "webrtc"
@export var QUESTstartupprotocol = "webrtc"

# symlinks from the addons directory
# ln -s ../../LorienAsset/lorien/addons/LorienInfiniteCanvas/
# ln -s ../../godot-xr-tools_IN_XR_Networking/addons/godot-xr-tools/ .
#    checkouted with single-pointer branch

#    don't forget to checkout to 2.5.0

# We will consider making my own FPConroller with these other sub-controllers in it

# Working to get the right hand tracking values to copy in
# Then work out how to write a pose, or assign a pose to something



func _ready():
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

	#get_node("/root").msaa = SubViewport.MSAA_4X
	$FPController/RightHandController.connect("button_pressed", Callable(self, "vr_right_button_pressed"))
	$FPController/RightHandController.connect("button_released", Callable(self, "vr_right_button_release"))
	$FPController/LeftHandController.connect("button_pressed", Callable(self, "vr_left_button_pressed"))
	$FPController/LeftHandController.set_process(false)
	$FPController/RightHandController.set_process(false)


	$FPController/PlayerBody.default_physics.move_drag = 45
	$SportBall.connect("body_entered", Callable(self, "ball_body_entered"))
	$SportBall.connect("body_exited", Callable(self, "ball_body_exited"))

	NetworkGateway.set_process_input(false)
	if webrtcroomname:
		NetworkGateway.get_node("MQTTsignalling/roomname").text = webrtcroomname

func ball_body_entered(body):
	#print("ball_body_entered ", body)
	if body.name == "PaddleBody":
		$SportBall/bouncesound.play()
		body.get_node("CollisionShape3D/MeshInstance3D").get_surface_override_material(0).emission_enabled = true
		await get_tree().create_timer(0.2).timeout
		body.get_node("CollisionShape3D/MeshInstance3D").get_surface_override_material(0).emission_enabled = false
		
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
	
func pose_right_button_pressed(button: int):
	print("pose_right_button_pressed ", button)

func vr_right_button_pressed(button: int):
	print("vr right button pressed ", button)
	if button == VR_BUTTON_BY:
		if $ViewportNetworkGateway.visible:
			$ViewportNetworkGateway.visible = false
		else:
			var headtrans = $FPController/XRCamera3D.global_transform
			$ViewportNetworkGateway.look_at_from_position(headtrans.origin + headtrans.basis.z*-3, 
														  headtrans.origin + headtrans.basis.z*-3, 
														  Vector3(0, 1, 0))
			$ViewportNetworkGateway.visible = true
			
	if button == VR_GRIP:
		pass #if NetworkGateway.get_node("PlayerConnections").LocalPlayer.has_method("setpaddlebody"):
		#	NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(true)

	
func vr_right_button_release(button: int):
	if button == VR_GRIP:
		if NetworkGateway.get_node("PlayerConnections").LocalPlayer.has_method("setpaddlebody"):
			NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(false)

func vr_left_button_pressed(button: int):
	print("vr left button pressd ", button)
	if button == VR_BUTTON_BY:
		$SportBall.transform.origin = $FPController/XRCamera3D.global_transform.origin + \
									  Vector3(0, 2, 0) + \
									  $FPController/XRCamera3D.global_transform.basis.z*-0.75
		
	if button == VR_BUTTON_AX:
		pass
	if button == VR_BUTTON_4:
		pass
		#$FPController/HandtrackingDevelopment.lefthandfingertap()
		#print("Publishing Right hand XR transforms to mqtt hand/pos")
		#$ViewportNetworkGateway/Viewport/NetworkGateway/MQTTsignalling/MQTT.publish("hand/pos", var2str($FPController/OpenXRallhandsdata.joint_transforms_R))

			
func _input(event):
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_M and event.pressed:
			vr_right_button_pressed(VR_BUTTON_BY)
		if event.keycode == KEY_F and event.pressed:
			vr_left_button_pressed(VR_BUTTON_BY)
		if event.keycode == KEY_G and event.pressed:
			NetworkGateway.get_node("PlayerConnections/Doppelganger").button_pressed = not NetworkGateway.get_node("PlayerConnections/Doppelganger").pressed
		if (event.keycode == KEY_2):
			NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS.LOCAL_NETWORK)
		if event.keycode == KEY_SHIFT:
			vr_right_button_pressed(VR_GRIP) if event.pressed else vr_right_button_release(VR_GRIP)
		if event.keycode == KEY_Q and event.pressed:
			var mqtt = get_node("/root/Main/ViewportNetworkGateway/SubViewport/NetworkGateway/MQTTsignalling/MQTT")
			mqtt.publish("hand/pos", "hithere")

func _physics_process(delta):
	var lowestfloorheight = -30
	if $FPController.transform.origin.y < lowestfloorheight:
		$FPController.transform.origin = Vector3(0, 2, 0)
	if has_node("SportBall"):
		if $SportBall.transform.origin.y < -3:
			$SportBall.transform.origin = Vector3(0, 2, -3)


func _process(delta):
	#$FPController/LeftHandController/FunctionPickup.enabled = not $FPController/ARVRController3.get_is_active()
	#$FPController/RightHandController/FunctionPickup.enabled = not $FPController/ARVRController4.get_is_active()
	#if $FPController.interface != null and $FPController/OpenXRallhandsdata.is_active_R:
	#	$FPController/RightHandController/FunctionPointer.active_button = VR_HANDTRACKING_INDEXTHUMB_PINCH
	#else:
	#	$FPController/RightHandController/FunctionPointer.active_button = VR_TRIGGER
	pass
	

#** Remove the debug printing messages
#** make the -1 controllerid named
#** test out drawing laser in contact only case
#** shorten laser to contact point PR to the toolkit
#** try out the function pickup case with the hands
#** clean up the hand finger drawing code more so
#** viewport network gateway on wrong setting at startup (enet instead of webrtc) error
#** check networking all still works
#** networking wristband
#** make a video and make the case for unified pointer rather than 4 pointers
#** try out the physics pointer for finger too
#** experiment with the climb pointer (where any of the fingers must be in contact)

#** play through elixir
#** hand tracking movement of vrchat and eolia

#** more work on the drawing in 2D
#** networking of that in experiments (first in alone in it)

#** consider the dinosaur
#** does it work in different world scales?
#** consider the dinosaur avatar as a mechanoid
