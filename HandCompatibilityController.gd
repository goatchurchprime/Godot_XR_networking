@tool
extends XRController3D


var corresponding_handcontroller : XRController3D
var corresponding_handcontroller_remotetransform : RemoteTransform3D

# Called when the node enters the scene tree for the first time.
func _ready():
	corresponding_handcontroller = ARVRHelpers._get_controller(self, "XXXX", controller_id+2, NodePath(""))

	corresponding_handcontroller_remotetransform = RemoteTransform3D.new()
	var poslayernode = "../../"+get_name()+"/"+get_child(0).get_name()
	corresponding_handcontroller_remotetransform.remote_path = NodePath(poslayernode)
	corresponding_handcontroller_remotetransform.update_position = false
	corresponding_handcontroller_remotetransform.update_rotation = false
	corresponding_handcontroller_remotetransform.update_scale = false
	corresponding_handcontroller.add_child(corresponding_handcontroller_remotetransform)

	corresponding_handcontroller.connect("button_pressed", Callable(self, "_on_hand_button_pressed"))
	corresponding_handcontroller.connect("button_released", Callable(self, "_on_hand_button_release"))

func _on_hand_button_pressed(button : int) -> void:
	print("   _on_hand_button_pressed ", button)
	if button == XRTools.Buttons.VR_BUTTON_AX:
		emit_signal("button_pressed", XRTools.Buttons.VR_TRIGGER)
	
func _on_hand_button_release(button : int) -> void:
	if button == XRTools.Buttons.VR_BUTTON_AX:
		emit_signal("button_released", XRTools.Buttons.VR_TRIGGER)

func _get_configuration_warnings():
	if get_child_count() != 1:
		return "Must have single node positioning layer under controller"
	var chand = ARVRHelpers._get_controller(self, "XXXX", controller_id+2, NodePath(""))
	if chand == null:
		return "Missing XRController3D.controller_id = %d" % (controller_id+2)
	return ""

var prevactive = false
func get_is_active() -> bool:
	var res = super.get_is_active()
	if res != prevactive:
		prevactive = res
		print(" controller ", controller_id, " now ", ("active" if res else "INactive"))
		get_child(0).transform = Transform3D()
	return res

func get_joystick_axis(pickup_axis_id : int) -> float:
	if corresponding_handcontroller.get_is_active():
		if pickup_axis_id == XRTools.Axis.VR_GRIP_AXIS:
			return corresponding_handcontroller.get_joystick_axis(XRTools.Axis.VR_SECONDARY_X_AXIS)
		return 0.0
	return super.get_joystick_axis(pickup_axis_id)

var cprevactive = false
func _physics_process(delta):
	if corresponding_handcontroller:
		var cres = corresponding_handcontroller.get_is_active()
		if cres != cprevactive:
			cprevactive = cres
			print(" CORR_controller ", controller_id, " now ", ("active" if cres else "INactive"))
			if cres:
				corresponding_handcontroller_remotetransform.update_position = true
				corresponding_handcontroller_remotetransform.update_rotation = true
			else:
				corresponding_handcontroller_remotetransform.update_position = false
				corresponding_handcontroller_remotetransform.update_rotation = false
				get_child(0).transform = Transform3D()


# check that RemoteTransform seems to make one extra mapping 
# when set in the physics process
