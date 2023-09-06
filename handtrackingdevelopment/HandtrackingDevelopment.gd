extends Node

@onready var arvrorigin = get_node("/root/Main/FPController")
@onready var arvrcamera = arvrorigin.get_node("XRCamera3D")

const horizontal_speed = 2.0
func _process(delta):
	if XRServer.primary_interface == null:
		var dlr = (-1 if Input.is_action_pressed("ui_left") else 0) + (1 if Input.is_action_pressed("ui_right") else 0)
		var dud = (-1 if Input.is_action_pressed("ui_up") else 0) + (1 if Input.is_action_pressed("ui_down") else 0)
		if dlr != 0 or dud != 0:
			if Input.is_action_pressed("ui_shift"):
				arvrcamera.rotation_degrees.x = clamp(arvrcamera.rotation_degrees.x - 90*delta*dud, -89, 89)
				arvrcamera.rotation_degrees.y = arvrcamera.rotation_degrees.y - 90*delta*dlr

			elif Input.is_action_pressed("ui_control"):
				var ftm = arvrorigin.get_node("RightHandController/Function_Turn_movement")
				ftm._rotate_player(arvrorigin.get_node("PlayerBody"), ftm.smooth_turn_speed*delta*dlr)
				arvrcamera.global_transform.origin += arvrcamera.global_transform.basis.z.normalized()*(dud*delta*horizontal_speed)

			else:
				arvrorigin.transform.origin += arvrcamera.global_transform.basis.x.normalized()*(dlr*delta*horizontal_speed) + \
											   arvrcamera.global_transform.basis.z.normalized()*(dud*delta*horizontal_speed)

			
