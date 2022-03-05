extends Spatial

onready var NetworkGateway = $ViewportNetworkGateway/Viewport/NetworkGateway

func _ready():
	#var brokeraddress = "ws://broker.mqttdashboard.com:8000"
	#var brokeraddress = "broker.mqttdashboard.com"
	var roomname = "cucumber"
	var brokeraddress = "mqtt.dynamicdevices.co.uk"
	NetworkGateway.initialstatemqttwebrtc(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY, roomname, brokeraddress)
	
	print("  Available Interfaces are %s: " % str(ARVRServer.get_interfaces()));
	var interface = ARVRServer.find_interface("OVRMobile")
	if interface and interface.initialize():
		print("Initialized the OVRMobile interface!!!")
		get_viewport().arvr = true
		OS.vsync_enabled = false
		Engine.iterations_per_second= 90
		set_process(false)

	$ARVROrigin/ARVRController_Right.connect("button_pressed", self, "vr_right_button_pressed")

const VR_BUTTON_BY = 1
func vr_right_button_pressed(button: int):
	print("vr right button pressed ", button)
	if button == VR_BUTTON_BY:
		if $ViewportNetworkGateway.visible:
			$ViewportNetworkGateway.visible = false
		else:
			var headtrans = $ARVROrigin/ARVRCamera.global_transform
			$ViewportNetworkGateway.look_at_from_position(headtrans.origin + headtrans.basis.z*-3, 
														  headtrans.origin + headtrans.basis.z*-3, 
														  Vector3(0, 1, 0))
			$ViewportNetworkGateway.visible = true
			
func _input(event):
	if event is InputEventKey and event.scancode == KEY_M and event.pressed and not event.echo:
		vr_right_button_pressed(VR_BUTTON_BY)


func _physics_process(delta):
	if $ARVROrigin.transform.origin.y < -30:
		$ARVROrigin.transform.origin = Vector3(0, 2, 0)
