extends Node3D

# Hold E and 2 down to simulate the context sensitive menu

@onready var FunctionPointer = get_node("../FunctionPointer")
@onready var ContextOperatingNode = XRHelpers.get_xr_origin(self).get_node("../GeonPoseMaker")

var selectedsignmaterial = load("res://contextui/selectedsign.tres")
var unselectedsignmaterial = load("res://contextui/unselectedsign.tres")
var contextbutton = "ax_button"
var actionbutton = "trigger_click"
var contextmenuclass = load("res://contextui/contextmenu.tscn")

var currentactivecontextmenuitem = -1
var spawnlocation = Vector3()

var contextdiscdistance = 0.4
var contextdiscradius = 0.15

var contextmenutarget = null
var cmitexts = [ ]

var contextclocksequence = [6, 8, 4, 9, 3, 10, 2, 12, 1, 11, 5, 7]

func controller_button_pressed(name, controller):
	if controller == FunctionPointer._active_controller:
		if name == contextbutton:
			if not visible:
				makecontextUI()
				spawnlocation = FunctionPointer.get_node("Laser").global_transform.origin

func controller_button_released(name, controller):
	if visible:
		if name == contextbutton:
			releasecontextUI()
		if name == actionbutton:
			releasecontextUI()

func makecontextUI():
	contextmenutarget = FunctionPointer.last_target
	cmitexts = ContextOperatingNode.makecontextmenufor(contextmenutarget, FunctionPointer.last_collided_at)

	var b = FunctionPointer.transform.basis
	var cp = b.y*FunctionPointer.y_offset - b.z*contextdiscdistance
	var cpos = FunctionPointer.transform.origin + cp*FunctionPointer._world_scale
	var pgt = get_parent().global_transform
	look_at_from_position(pgt*cpos, pgt*(cpos - b.z), Vector3(0,1,0))
	#print(transform)
	#transform = Transform3D(b, cpos)
	#print(transform)
	
	for i in range(len(cmitexts)):
		var contextmenuitem = contextmenuclass.instantiate()
		contextmenuitem.connect("pointer_event", _on_pointer_event.bind(contextmenuitem, i))
		contextmenuitem.setnamepos(cmitexts[i], contextclocksequence[i], contextdiscradius)
		contextmenuitem.setunselected(unselectedsignmaterial)
		add_child(contextmenuitem)
	await get_tree().process_frame # necessary to set the text dimensions
	for contextmenuitem in get_children():
		contextmenuitem.setbackgroundcollision()
	visible = true
	
func releasecontextUI():
	visible = false
	if currentactivecontextmenuitem != -1:
		print("currentactivecontextmenuitem:: ", currentactivecontextmenuitem)
		ContextOperatingNode.call_deferred("contextmenuitemselected", contextmenutarget, cmitexts[currentactivecontextmenuitem], spawnlocation)
		currentactivecontextmenuitem = -1
	for contextmenuitem in get_children():
		contextmenuitem.queue_free()
	contextmenutarget = FunctionPointer.target
	cmitexts = [ ]
	

func _on_pointer_event(e : XRToolsPointerEvent, contextmenuitem, i):
	if e.event_type == XRToolsPointerEvent.Type.ENTERED:
		contextmenuitem.setselected(selectedsignmaterial)
		currentactivecontextmenuitem = i
		
	if e.event_type == XRToolsPointerEvent.Type.EXITED:
		contextmenuitem.setunselected(unselectedsignmaterial)
		currentactivecontextmenuitem = -1

		
func _ready():
	visible = false
	var _controller_left_node = XRHelpers.get_left_controller(self)
	_controller_left_node.button_pressed.connect(controller_button_pressed.bind(_controller_left_node))
	_controller_left_node.button_released.connect(controller_button_released.bind(_controller_left_node))
	var _controller_right_node = XRHelpers.get_right_controller(self)
	_controller_right_node.button_pressed.connect(controller_button_pressed.bind(_controller_right_node))
	_controller_right_node.button_released.connect(controller_button_released.bind(_controller_right_node))
	

