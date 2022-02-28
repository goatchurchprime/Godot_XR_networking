extends Spatial

func _ready():
	print("  Available Interfaces are %s: " % str(ARVRServer.get_interfaces()));
	var interface = ARVRServer.find_interface("OVRMobile")
	if interface and interface.initialize():
		print("Initialized the OVRMobile interface!!!")
		get_viewport().arvr = true
		OS.vsync_enabled = false
		Engine.iterations_per_second= 90
