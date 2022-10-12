extends Spatial


func _ready():
	if has_node("ViewportLorienCanvas"):
		$ViewportLorienCanvas.connect("pointer_entered", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "enable")
		$ViewportLorienCanvas.connect("pointer_exited", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "disable")
		var project = ProjectManager.add_project()
		ProjectManager.make_project_active(project)
		$ViewportLorienCanvas/Viewport/InfiniteCanvas.use_project(project)

	var remotetransformleftindextip = RemoteTransform.new()
	var leftindextipnode = get_node("../FPController/Left_hand/Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip")
	leftindextipnode.add_child(remotetransformleftindextip)
	remotetransformleftindextip.remote_path = NodePath("../../../../../../../../../LorienHandControls/LeftIndexFinger")

	var remotetransformrightindextip = RemoteTransform.new()
	var rightindextipnode = get_node("../FPController/Right_hand/Wrist/IndexMetacarpal/IndexProximal/IndexIntermediate/IndexDistal/IndexTip")
	rightindextipnode.add_child(remotetransformrightindextip)
	remotetransformrightindextip.remote_path = NodePath("../../../../../../../../../LorienHandControls/RightIndexFinger")

var Dw = 2
func _on_AreaResetpos_body_entered(body):
	print("_on_AreaResetpos_body_entered ", body)
	var event = InputEventMouseButton.new()
	Dw += 1
	event.set_button_index(BUTTON_WHEEL_DOWN if (Dw%10)<5 else BUTTON_WHEEL_UP)
	event.set_position(Vector2(300,200))
	event.set_global_position(Vector2(300,200))
	event.set_pressed(true)
	event.set_button_mask(0)
	#$ViewportLorienCanvas/Viewport.input(event)  # not getting cycled through as the tool event
	$ViewportLorienCanvas/Viewport/InfiniteCanvas/Viewport/Camera2D.tool_event(event)

func _on_Area_body_exited(body):
	print("_on_Area_body_exited ", body)
