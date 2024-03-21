extends Node3D

@onready var controller = get_node("../../RightHandController")

var markerpoint = null
var blindmarkerpoint = null
var markerline = null
var blindmarkerline = null

var tbuttondown = Time.get_ticks_msec()
var controllertransformdown = null
var probelinetransformdown = null
func buttonpressed(name):  # primary_touch or primary_click
	print("--- Controller button pressed ", name)
	if name == "primary_click":
		tbuttondown = Time.get_ticks_msec()
	if name == "trigger_click":
		if controller.is_button_pressed("by_touch"):
			var mm = markerline.duplicate()
			mm.transform.basis = $ProbeLine.transform.basis
			add_child(mm)
		else:
			var mm = markerpoint.duplicate()
			mm.rotation_degrees = $ProbePoint.rotation_degrees
			add_child(mm)
	if name == "grip_click":
		if controller.is_button_pressed("by_touch"):
			var mm = blindmarkerline.duplicate()
			mm.transform.basis = $ProbeLine.transform.basis
			add_child(mm)
		else:
			var mm = blindmarkerpoint.duplicate()
			mm.rotation_degrees = $ProbePoint.rotation_degrees
			add_child(mm)


	if name == "by_button":
		$ProbeLine.visible = true
		controllertransformdown = controller.transform
		probelinetransformdown = $ProbeLine.transform

# by_button

func buttonreleased(name):
	print("--- Controller button pressed ", name)
	if name == "primary_click":
		var tbuttonduration = Time.get_ticks_msec() - tbuttondown
		if tbuttonduration > 2000:
			visible = not visible
		elif tbuttonduration > 500:
			var s = $FocusPoint/FocusMesh.get_surface_override_material(0)
			s.set_shader_parameter("blockleft", not s.get_shader_parameter("blockleft"))
		else:
			if get_child_count() > 2:
				remove_child(get_child(get_child_count() - 1))

	if name == "by_button":
		controllertransformdown = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var v = controller.get_vector2("primary")
	var deadspace = 0.1
	var degpersec = 2.0
	var degreelimit = 30.0
	if abs(v.x) > 0.1:
		$ProbePoint.rotation_degrees.y = clamp($ProbePoint.rotation_degrees.y - (abs(v.x) - deadspace)*delta*degpersec*sign(v.x), -degpersec, degreelimit)
	if abs(v.y) > 0.1:
		$ProbePoint.rotation_degrees.x = clamp($ProbePoint.rotation_degrees.x + (abs(v.y) - deadspace)*delta*degpersec*sign(v.y), -degpersec, degreelimit)

	if controllertransformdown != null:
		var cdiff = controllertransformdown.inverse()*controller.transform
		var btrans = cdiff*probelinetransformdown
		$ProbeLine.transform.basis = btrans.basis

func _ready():
	controller.button_pressed.connect(buttonpressed)
	controller.button_released.connect(buttonreleased)
	markerpoint = $MarkerPoint
	remove_child(markerpoint)
	blindmarkerpoint = $BlindMarkerPoint
	remove_child(blindmarkerpoint)
	markerline = $MarkerLine
	remove_child(markerline)
	blindmarkerline = $BlindMarkerLine
	remove_child(blindmarkerline)
