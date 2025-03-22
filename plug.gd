extends "res://addons/gd-plug/plug.gd"

func _plugging():
	# plug("imjp94/gd-YAFSM") # By default, gd-plug will only install anything from "addons/" directory
	# plug("imjp94/gd-YAFSM", {"include": ["addons/"]})
	plug("GodotVR/godot-xr-tools", {"commit": "4d53140015ba5feb6f6ec07873f050311ffe1fdc"})
	plug("Cafezinhu/godot-vr-simulator", {"commit": "5bedbbacf6fe40af10e0bfea99487c84387b19f3"})
	plug("goatchurchprime/godot-mqtt")
	plug("goatchurchprime/godot_multiplayer_networking_workbench", {"include":["addons/player-networking"]})
	plug("Godot-Dojo/Godot-XR-AH", {"include":["addons/xr-autohandtracker"]})
