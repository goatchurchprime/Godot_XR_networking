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

	$ViewportLorienCanvas/Viewport/InfiniteCanvas.enable()


var Dw = 2
func _on_AreaZoom_body_entered(body):
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

func _on_AreaResetpos_body_entered(body):
	print("Reset position")
	$ViewportLorienCanvas.transform.origin = $RightIndexFinger.transform.origin

var activefingerheight = 0.018
var vpfingerposPrev = Vector2(0,0)
var indexfingerActive = false
func _process(delta):
	var p_at = $RightIndexFinger.transform.origin
	var indexfingerpos = $ViewportLorienCanvas.transform.xform_inv(p_at)

	if indexfingerpos.z > -activefingerheight and indexfingerpos.z < activefingerheight:
		var screen_size = $ViewportLorienCanvas.screen_size
		var viewport_size = $ViewportLorienCanvas.viewport_size
		var ax = ((indexfingerpos.x / screen_size.x) + 0.5) * viewport_size.x
		var ay = (0.5 - (indexfingerpos.y / screen_size.y)) * viewport_size.y
		var vpfingerpos = Vector2(ax, ay)

		if not indexfingerActive:
			var event = InputEventMouseButton.new()
			event.set_button_index(BUTTON_LEFT)
			event.set_pressed(true)
			event.set_position(vpfingerpos)
			event.set_global_position(vpfingerpos)
			event.set_button_mask(1)
			$ViewportLorienCanvas/Viewport.input(event)
			indexfingerActive = true
			
		if (vpfingerposPrev - vpfingerpos).length() > 0.001:
			var event = InputEventMouseMotion.new()
			event.set_position(vpfingerpos)
			event.set_global_position(vpfingerpos)
			event.set_relative(Vector2(vpfingerpos.x-vpfingerposPrev.x, vpfingerpos.y-vpfingerposPrev.y))
			event.set_button_mask(1)
			event.set_pressure(min(1.0, inverse_lerp(-activefingerheight, 0.0, indexfingerpos.z)))
			$ViewportLorienCanvas/Viewport.input(event)
			vpfingerposPrev = vpfingerpos
		
	elif indexfingerActive:
		var event = InputEventMouseButton.new()
		event.set_button_index(BUTTON_LEFT)
		event.set_pressed(false)
		event.set_position(vpfingerposPrev)
		event.set_global_position(vpfingerposPrev)
		event.set_button_mask(0)
		$ViewportLorienCanvas/Viewport.input(event)
		indexfingerActive = false
