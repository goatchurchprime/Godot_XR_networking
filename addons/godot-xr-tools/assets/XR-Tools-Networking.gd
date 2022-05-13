extends Node

onready var NetworkGateway = $ViewportNetworkGateway/Viewport/NetworkGateway

export var webrtcroomname = "lettuce"
export var webrtcbroker = "mqtt.dynamicdevices.co.uk"
# "ws://broker.mqttdashboard.com:8000"
export var PCstartupprotocol = "webrtc"
export var QUESTstartupprotocol = "webrtc"
export (NodePath) var fpcontroller_path
export (NodePath) var leftcontroller_path
export (NodePath) var rightcontroller_path


enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}

#need to add export variable for choosing whether to associate the pop up button with left or right controller but this will do for now the minute.

export (Buttons) var networking_popup_menu_button = Buttons.VR_BUTTON_BY 

var _fpcontroller = null
var _leftcontroller = null
var _rightcontroller = null

func _ready():
	_fpcontroller = get_node(fpcontroller_path)
	_leftcontroller = get_node(leftcontroller_path)
	_rightcontroller = get_node(rightcontroller_path)


##COMMENTING THIS OUT FOR NOW BECAUSE RELIES ON MODIFIED FP CONTROLLER THAT DOES NOT EXIST YET IN MASTER##	
#	if not OS.has_feature("QUEST"):
#		_fpcontroller.get_node("Left_hand/Wrist").set_process(false)
#		_fpcontroller.get_node("Left_hand/Wrist").set_physics_process(false)
#		_fpcontroller.get_node("Right_hand/Wrist").set_process(false)
#		_fpcontroller.get_node("Right_hand/Wrist").set_physics_process(false)
#		_fpcontroller.get_node("Left_hand").queue_free()
#		_fpcontroller.get_node("Right_hand").queue_free()
		
#	$FPController/LeftHandController/Function_Direct_movement.nonVRkeyboard = true

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
			

	get_node("/root").msaa = Viewport.MSAA_4X
	
	_rightcontroller.connect("button_pressed", self, "vr_right_button_pressed")
	_rightcontroller.connect("button_release", self, "vr_right_button_release")
	_leftcontroller.connect("button_pressed", self, "vr_left_button_pressed")
	_leftcontroller.connect("button_release", self, "vr_right_button_release")
	
	NetworkGateway.set_process_input(false)


func vr_right_button_pressed(button: int):
#	print("vr right button pressed ", button)
	if button == networking_popup_menu_button:
		if $ViewportNetworkGateway.visible:
			$ViewportNetworkGateway.visible = false
		else:
			var headtrans = _fpcontroller.get_node("ARVRCamera").global_transform
			$ViewportNetworkGateway.look_at_from_position(headtrans.origin + headtrans.basis.z*-3, 
														  headtrans.origin + headtrans.basis.z*-3, 
														  Vector3(0, 1, 0))
			$ViewportNetworkGateway.visible = true

func vr_left_button_pressed(button: int):
#	print("vr left button pressed ", button)
	if button == networking_popup_menu_button:
		if $ViewportNetworkGateway.visible:
			$ViewportNetworkGateway.visible = false
		else:
			var headtrans = _fpcontroller.get_node("ARVRCamera").global_transform
			$ViewportNetworkGateway.look_at_from_position(headtrans.origin + headtrans.basis.z*-3, 
														  headtrans.origin + headtrans.basis.z*-3, 
														  Vector3(0, 1, 0))
			$ViewportNetworkGateway.visible = true

func _input(event):
	if event is InputEventKey and not event.echo:
		if event.scancode == KEY_M and event.pressed:
			vr_right_button_pressed(networking_popup_menu_button)
		if event.scancode == KEY_G and event.pressed:
			NetworkGateway.get_node("PlayerConnections/Doppelganger").pressed = not NetworkGateway.get_node("PlayerConnections/Doppelganger").pressed
		if (event.scancode == KEY_2):
			NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS.LOCAL_NETWORK)
		
func _physics_process(delta):
	var lowestfloorheight = -30
	if _fpcontroller.transform.origin.y < lowestfloorheight:
		_fpcontroller.transform.origin = Vector3(0, 2, 0)
		
		
			
