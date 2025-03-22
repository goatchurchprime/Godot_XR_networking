extends Node3D

@onready var NetworkGateway = $ViewportNetworkGateway/Viewport/NetworkGateway

@export var webrtcroomname = "grapefruit"

#export var webrtcbroker = "mosquitto.doesliverpool.xyz"

# use this one for WebXR because it can only come from HTML5 served from an https:// link
#@export var webrtcbroker = "wss://mosquitto.doesliverpool.xyz:8081"
#export var webrtcbroker = "ws://mosquitto.doesliverpool.xyz:8080"
#export var webrtcbroker = "ssl://mosquitto.doesliverpool.xyz:8884"
@export var webrtcbroker = "mosquitto.doesliverpool.xyz"


# "ws://broker.mqttdashboard.com:8webrtcbroker000"
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
	print("AudioServer.get_input_device_list ", AudioServer.get_input_device_list())
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

	#get_node("/root").msaa = SubViewport.MSAA_4X
	$XROrigin3D/RightHandController.button_pressed.connect(vr_right_button_pressed)
	$XROrigin3D/RightHandController.button_released.connect(vr_right_button_release)
	$XROrigin3D/LeftHandController.button_pressed.connect(vr_left_button_pressed)


	$XROrigin3D/PlayerBody.default_physics.move_drag = 45
	NetworkGateway.set_process_input(false)
	if webrtcroomname:
		NetworkGateway.MQTTsignalling.Roomnametext.text = webrtcroomname

func vr_right_button_pressed(button: String):
	print("vr right button pressed ", button)
	if button == "by_button":
		if $ViewportNetworkGateway.visible:
			$ViewportNetworkGateway.visible = false
		else:
			var headtrans = $XROrigin3D/XRCamera3D.global_transform
			$ViewportNetworkGateway.look_at_from_position(headtrans.origin + headtrans.basis.z*-3, 
														  headtrans.origin + headtrans.basis.z*-3, 
														  Vector3(0, 1, 0))
			$ViewportNetworkGateway.visible = true
			

	
func vr_right_button_release(button: String):
	pass
	
func vr_left_button_pressed(button: String):
	print("vr left button pressd ", button)
	if button == "ax_button":
		pass
	if button == "by_button":
		#$FPController/HandtrackingDevelopment.lefthandfingertap()
		print("Publishing Right hand XR transforms to mqtt hand/pos")
		#$ViewportNetworkGateway/Viewport/NetworkGateway/MQTTsignalling/MQTT.publish("hand/pos", var_to_str($XROrigin3D/OpenXRallhandsdata.joint_transforms_R))


func _input(event):
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_Q and event.pressed:
			print("AudioServer.get_input_device_list ", AudioServer.get_input_device_list())
			print("AudioServer.get_input_device ", AudioServer.get_input_device())

		if event.keycode == KEY_M and event.pressed:
			vr_right_button_pressed("by_button")
		if event.keycode == KEY_F and event.pressed:
			vr_left_button_pressed("by_button")
		if event.keycode == KEY_G and event.pressed:
			NetworkGateway.DoppelgangerPanel.get_node("hbox/VBox_enable/DoppelgangerEnable").button_pressed = not NetworkGateway.DoppelgangerPanel.get_node("hbox/VBox_enable/DoppelgangerEnable").button_pressed
		#if (event.keycode == KEY_2):
		#	NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS.LOCAL_NETWORK)
		#if (event.keycode == KEY_3):
		#	NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS.AS_SERVER)
		#if (event.keycode == KEY_3):
		#	NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS.AS_SERVER)

		if (event.keycode == KEY_4) and event.pressed:
			NetworkGateway.PlayerConnections.LocalPlayer.projectedhands = not NetworkGateway.get_node("PlayerConnections").LocalPlayer.projectedhands
			
		if (event.keycode == KEY_C) and event.pressed:
			_on_interactable_area_button_button_pressed(null)


		#if event.keycode == KEY_SHIFT:
		#	vr_right_button_pressed("grip_click") if event.pressed else vr_right_button_release("grip_click")
		#if event.keycode == KEY_Q and event.pressed:
		#	var mqtt = get_node("/root/Main/ViewportNetworkGateway/SubViewport/NetworkGateway/MQTTsignalling/MQTT")
		#	mqtt.publish("hand/pos", "hithere")

func _physics_process(delta):
	var lowestfloorheight = -30
	if $XROrigin3D.transform.origin.y < lowestfloorheight:
		$XROrigin3D.transform.origin = Vector3(0, 2, 0)


func _process(delta):
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


func _on_interactable_area_button_button_pressed(button):
	if NetworkGateway.is_disconnected():
		NetworkGateway.simple_webrtc_connect(webrtcroomname)
	if button:
		button.get_node("Label3D").text = "X"
