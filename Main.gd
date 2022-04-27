extends Spatial

onready var NetworkGateway = $ViewportNetworkGateway/Viewport/NetworkGateway

func openxrcontinueinitializing(interface):
	print("OpenXR Interface initialized")

	# Find the viewport we're using to render our XR output
	var vp = get_viewport()

	# Start passthrough?
	if false:
		vp.transparent_bg = true
		$ARVROrigin/XRConfiguration.start_passthrough()

	# Connect to our plugin signals
	ARVRServer.connect("openxr_session_begun", self, "_on_openxr_session_begun")
	ARVRServer.connect("openxr_session_ending", self, "_on_openxr_session_ending")
	ARVRServer.connect("openxr_focused_state", self, "_on_openxr_focused_state")
	ARVRServer.connect("openxr_visible_state", self, "_on_openxr_visible_state")
	ARVRServer.connect("openxr_pose_recentered", self, "_on_openxr_pose_recentered")

	# Change our viewport so it is tied to our ARVR interface and renders to our HMD
	vp.arvr = true

	# We can't set keep linear yet because we won't know the correct value until after our session has begun.

	# increase our physics engine update speed
	var refresh_rate = $ARVROrigin/XRConfiguration.get_refresh_rate()
	if refresh_rate == 0:
		# Only Facebook Reality Labs supports this at this time
		print("No refresh rate given by XR runtime")

		# Use something sufficiently high
		Engine.iterations_per_second = 144
	else:
		print("HMD refresh rate is set to " + str(refresh_rate))

		# Match our physics to our HMD
		Engine.iterations_per_second = refresh_rate

func _on_openxr_session_begun():
	print("OpenXR session begun")

	var vp : Viewport = get_viewport()
	if vp:
		# Our interface will tell us whether we should keep our render buffer in linear color space
		vp.keep_3d_linear = $ARVROrigin/XRConfiguration.keep_3d_linear()

func _on_openxr_session_ending():
	print("OpenXR session ending")

func _on_openxr_focused_state():
	print("OpenXR focused state")

func _on_openxr_visible_state():
	print("OpenXR visible state")

func _on_openxr_pose_recentered():
	print("OpenXR pose recentered")



func _ready():
	#var brokeraddress = "ws://broker.mqttdashboard.com:8000"
	#var brokeraddress = "broker.mqttdashboard.com"
	#var roomname = "cucumber"
	var roomname = "lettuce"
	var brokeraddress = "mqtt.dynamicdevices.co.uk"
	brokeraddress = NetworkGateway.get_node("MQTTsignalling/brokeraddress").text
	roomname = NetworkGateway.get_node("MQTTsignalling/roomname").text
	print("  Available Interfaces are %s: " % str(ARVRServer.get_interfaces()));
	var interface = ARVRServer.find_interface("OpenXR")
	if interface and interface.initialize():
		openxrcontinueinitializing(interface)
	else:
#		$ARVROrigin/ARVRController_Left/Function_Direct_movement.nonVRkeyboard = true
		NetworkGateway.initialstatemqttwebrtc(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY, roomname, brokeraddress)

	get_node("/root").msaa = Viewport.MSAA_4X
	$ARVROrigin/ARVRController_Right.connect("button_pressed", self, "vr_right_button_pressed")
	$ARVROrigin/ARVRController_Right.connect("button_release", self, "vr_right_button_release")
	$ARVROrigin/ARVRController_Left.connect("button_pressed", self, "vr_left_button_pressed")

	$ARVROrigin/PlayerBody.default_physics.move_drag = 45
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
			
	if button == VR_GRIP:
		NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(true)

func vr_right_button_release(button: int):
	if button == VR_GRIP:
		NetworkGateway.get_node("PlayerConnections").LocalPlayer.setpaddlebody(false)

func vr_left_button_pressed(button: int):
	print("vr left button pressed ", button)
	if button == VR_BUTTON_BY:
		$SportBall.transform.origin = $ARVROrigin/ARVRCamera.global_transform.origin + \
									  Vector3(0, 2, 0) + \
									  $ARVROrigin/ARVRCamera.global_transform.basis.z*-0.75
		
			
func _input(event):
	if event is InputEventKey and not event.echo:
		if event.scancode == KEY_M and event.pressed:
			vr_right_button_pressed(VR_BUTTON_BY)
		if event.scancode == KEY_F and event.pressed:
			vr_left_button_pressed(VR_BUTTON_BY)
		if event.scancode == KEY_G and event.pressed:
			NetworkGateway.get_node("PlayerConnections/Doppelganger").pressed = not NetworkGateway.get_node("PlayerConnections/Doppelganger").pressed
		if event.scancode == KEY_SHIFT:
			vr_right_button_pressed(VR_GRIP) if event.pressed else vr_right_button_release(VR_GRIP)


func _physics_process(delta):
	if $ARVROrigin.transform.origin.y < -30:
		$ARVROrigin.transform.origin = Vector3(0, 2, 0)
	if has_node("SportBall"):
		if $SportBall.transform.origin.y < -3:
			$SportBall.transform.origin = Vector3(0, 2, -3)

