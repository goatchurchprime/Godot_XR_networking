extends Node3D

# Hold E and 2 down to simulate the context sensitive menu

@onready var FunctionPointer = get_node("../FunctionPointer")
var selectedsignmaterial = load("res://contextui/selectedsign.tres")
var unselectedsignmaterial = load("res://contextui/unselectedsign.tres")
var contextbutton = "ax_button"
var actionbutton = "trigger_click"
var contextmenuclass = load("res://contextui/contextmenu.tscn")


var currentactivecontextmenuitem = -1

var contextdiscdistance = 0.8
var contextdiscradius = 0.3

var contextmenutarget = null
var cmitexts = [ ]

# These should be in the target stuff
func makecontextmenufor(target):
	print("contextmenutarget: ", target.name if target else "null")
	return [ "SIX6", "three3", "seven7", "eight", "do"]

func contextmenuitemselected(target, cmitext):
	print(target, cmitext)
	
	
func controller_button_pressed(name, controller):
	if controller == FunctionPointer._active_controller:
		if name == contextbutton:
			if not visible:
				makecontextUI()

func controller_button_released(name, controller):
	if visible:
		if name == contextbutton:
			releasecontextUI()
		if name == actionbutton:
			releasecontextUI()

func makecontextUI():
	contextmenutarget = FunctionPointer.last_target
	cmitexts = makecontextmenufor(contextmenutarget)

	var b = FunctionPointer.transform.basis
	var cp = b.y*FunctionPointer.y_offset - b.z*contextdiscdistance
	transform = Transform3D(b, FunctionPointer.transform.origin + cp*FunctionPointer._world_scale)
	
	for i in range(len(cmitexts)):
		var contextmenuitem = contextmenuclass.instantiate()
		contextmenuitem.connect("pointer_event", _on_pointer_event.bind(contextmenuitem, i))
		contextmenuitem.setnamepos(cmitexts[i], i, contextdiscradius)
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
		currentactivecontextmenuitem = -1
		call_deferred("contextmenuitemselected", contextmenutarget, cmitexts[currentactivecontextmenuitem])
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
	

