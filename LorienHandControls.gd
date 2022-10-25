extends Spatial

onready var OpenXRallhandsdata = get_node("../FPController/OpenXRallhandsdata")

func _ready():
	if has_node("ViewportLorienCanvas"):
#		$ViewportLorienCanvas.connect("pointer_entered", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "enable")
#		$ViewportLorienCanvas.connect("pointer_exited", $ViewportLorienCanvas/Viewport/InfiniteCanvas, "disable")
		var project = ProjectManager.add_project()
		ProjectManager.make_project_active(project)
		$ViewportLorienCanvas/Viewport/InfiniteCanvas.use_project(project)

	var remotetransformleftindextip = RemoteTransform.new()
	var leftindextipnode = OpenXRallhandsdata.get_node("LeftTipJT")
	leftindextipnode.add_child(remotetransformleftindextip)
	remotetransformleftindextip.remote_path = NodePath("../../../../LorienHandControls/LeftIndexFinger")

	var remotetransformrightindextip = RemoteTransform.new()
	var rightindextipnode = OpenXRallhandsdata.get_node("RightTipJT")
	rightindextipnode.add_child(remotetransformrightindextip)
	remotetransformrightindextip.remote_path = NodePath("../../../../LorienHandControls/RightIndexFinger")

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
	print("Reset position ", $RightIndexFinger.transform.origin)
	if $RightIndexFinger.transform.origin.y != 0.0:
		$ViewportLorienCanvas.transform.origin = $RightIndexFinger.transform.origin

var activefingerheight = 0.018
var vpfingerposPrev = Vector2(0,0)
var indexfingerActive = false
var LvpfingerposPrev = Vector2(0,0)
var LindexfingerActive = false

func detecthandintent():
	var bb = OpenXRallhandsdata.boundingbox_R
	if bb:
		var Lcanvaspos = $ViewportLorienCanvas.transform.origin
		if abs(bb.position.y - Lcanvaspos.y) < activefingerheight and bb.size.x < 0.08  and bb.size.y > 0.09:
			$FistPlate.translation = Vector3(bb.position.x + bb.size.x*0.5, bb.position.y, bb.position.z + bb.size.z*0.5)
			$FistPlate.visible = true
		else:
			$FistPlate.visible = false
	else:
		$FistPlate.visible = false
		
func _physics_process(delta):
	var p_at = $RightIndexFinger.transform.origin
	var indexfingerpos = $ViewportLorienCanvas.transform.xform_inv(p_at)
	detecthandintent()

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
			$RightIndexFinger/ActiveMarker.visible = true
			
		var vpfingervec = vpfingerpos - vpfingerposPrev 
		if vpfingervec.length() > 0.004:
			var event = InputEventMouseMotion.new()
			event.set_position(vpfingerpos)
			event.set_global_position(vpfingerpos)
			event.set_relative(vpfingervec)
			event.set_button_mask(1)
			event.set_pressure(min(1.0, 1.0 + indexfingerpos.z/activefingerheight))
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
		$RightIndexFinger/ActiveMarker.visible = false

	var Lp_at = $LeftIndexFinger.transform.origin
	var Lindexfingerpos = $ViewportLorienCanvas.transform.xform_inv(Lp_at)
	if  Lindexfingerpos.z > -activefingerheight and  Lindexfingerpos.z < activefingerheight:
		var screen_size = $ViewportLorienCanvas.screen_size
		var viewport_size = $ViewportLorienCanvas.viewport_size
		var ax = ((Lindexfingerpos.x / screen_size.x) + 0.5) * viewport_size.x
		var ay = (0.5 - (Lindexfingerpos.y / screen_size.y)) * viewport_size.y
		var Lvpfingerpos = Vector2(ax, ay)
		if LindexfingerActive:
			var Lvpfingervec = Lvpfingerpos - LvpfingerposPrev 
			if Lvpfingervec.length() > 0.001:
				$ViewportLorienCanvas/Viewport/InfiniteCanvas/Viewport/Camera2D._do_pan(Lvpfingervec)
		else:
			LindexfingerActive = true
			$LeftIndexFinger/ActiveMarker.visible = true
		LvpfingerposPrev = Lvpfingerpos
			
	elif LindexfingerActive:
		LindexfingerActive = false
		$LeftIndexFinger/ActiveMarker.visible = false
