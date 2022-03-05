extends Spatial

onready var NetworkGateway = $Viewport2Din3D/Viewport/NetworkGateway

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
