extends Spatial

onready var bright = (name.substr(0, 5) == "Right")
onready var OpenXRallhandsdata = get_node("/root/Main/FPController/OpenXRallhandsdata")

signal button_pressed(button)
signal button_release(button)

func _ready():
	print(name, " ", bright)

func get_is_active():
	var LRappendage = get_node("../RightAppendage") if bright else get_node("../LeftAppendage")
	var LRhand = LRappendage.get_child(0)
	var LRcontroller = LRappendage.get_child(1)
	return LRhand.visible or LRcontroller.visible

func get_joystick_axis(pickup_axis_id):
	return OpenXRallhandsdata.grippinchedjoyvalue_R if bright else OpenXRallhandsdata.grippinchedjoyvalue_L

